#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(data.table))
library(packcircles)
# library(scattermore)
library(graphics)
# library(ggchromatic)
# library(treemap)

green = "#5fb12a"
blue  = "#267592"
red   = "#e23a34"

# circle packing that centers.
circlePack = function(vals, sizetype) {
    df = circleProgressiveLayout(vals, sizetype=sizetype)
    x=df$x
    y=df$y
    r=df$radius
    x_c = (min(x-r) + max(x+r)) /2
    y_c = (min(y-r) + max(y+r)) /2
    data.table(x=x-x_c, y=y-y_c, r=r)
}

# circle packing that centers and does one round of optimising position.
circlePackOpt = function(vals, sizetype) {
    df = circleProgressiveLayout(vals, sizetype=sizetype)
    x=df$x
    y=df$y
    r=df$radius
    x_span = c(min(x-r), max(x+r))
    y_span = c(min(y-r), max(y+r))
    r_span = max(x_span[2]-x_span[1], y_span[2]-y_span[1]) / 2
    DT = data.table(x=x-mean(x_span), y=y-mean(y_span), r=r)
    # improve centering by taking average point between box estimate and the worst outlier
    dtt = DT[which.max(sqrt(x^2+y^2)+r), .(x, y, r, len=sqrt(x^2+y^2))]
    if(dtt$len > 0) {
        r_parent = dtt$len + dtt$r
        # how far to adjust in direction of outlier
        r_trans = r_parent - (r_span + r_parent) / 2
        trans = dtt[, .(x,y)] * (r_trans / dtt$len)
        DT[,c("x", "y") := .(x+trans$x, y+trans$y)]
    }
    DT
}

# circle packing that centers which shuffles and retries to find smallest fit. 
circlePackRnd = function(vals, sizetype, retries=4) {
    best_r_parent = Inf
    for (i in 1:retries) {
        idx = sample(1:length(vals))
        df = circleProgressiveLayout(vals[idx], sizetype=sizetype)
        x=df$x
        y=df$y
        r=df$radius
        df = data.table(x=x-(min(x-r)+max(x+r))/2, y=y-(min(y-r)+max(y+r))/2, r=r)
        r_parent = df[, max(sqrt(x^2+y^2)+r)]
        if (r_parent < best_r_parent) {
            best_r_parent = r_parent
            DT = df[order(idx)] # unshuffle + remember
        }
    }
    DT
}

getVerts = function(DT, n) {
    data.table(circleLayoutVertices(DT, xysizecols=c("x", "y", "r"), idcol="id", npoints=n))
}

rot = function(x, y, theta) {
    list(x=x*cos(theta) - y*sin(theta), y=x*sin(theta) + y*cos(theta))
}

dtn = fread("./taxNodes.tsv.gz")
dte = fread("./taxEdges.tsv.gz")
lRanks = c("domain", "kingdom", "phylum", "class", "order", "family", "genus", "species")
lDomains = c("B", "E", "A", "V")
dtn[, rank:=factor(rank, levels=lRanks)]
dtn[, domain:=factor(domain, levels=lDomains)]
# too few viruses too see
dtn = dtn[domain!="V"]

total = dtn[id=="O", proteins]
dtn = dtn[id != 'O']

dtn = merge(dtn, dte[, .(children=.N), by=parent], by.x="id", by.y="parent", all.x=TRUE)
dtn[is.na(children), children:=1]

dtn[, w_pp:=proteins/total]
dtn[, w:=children/sum(children), by=rank]
setorder(dtn, -w_pp)

dte[, child:=as.character(child)]

dten = merge(dtn, dte, by.x="id", by.y="child", all.x=TRUE)
dten[is.na(parent), parent:=domain]

# setorder(dten, -w_pp)
# dten[, h:=1/cor_nrep1]
# # have domain and kingdom share innermost circle
# domainsWithKingdom = dten[rank=="kingdom", unique(parent)]
# dten[rank%in%lRanks[1:2] & domain%in%domainsWithKingdom, h:=h/2]
#
# # set x (xmin) to cumsum for all children to a given parent, starting at the x of the parent.
# dten[, x:=cumsum(c(0,w_pp))[1:.N], by=parent]
# dten[,y:=h] 
#
# for(rnk in lRanks) {
#     dten = merge(dten, dten[,.(id,x,y)], all.x=TRUE, by.x="parent", by.y="id", suffixes=c("", "_parent"))
#     dten[rank=="domain", x_parent:=0]
#     dten = merge(dten, dten[, .(x_parent2=max(x), y_parent2=max(y)), by=rank], by="rank", all.x=TRUE)
#     dten[is.na(x_parent), x_parent:=x_parent2]
#     dten[is.na(y_parent), y_parent:=y_parent2]
#     dten[rank==rnk, x:=x+x_parent]
#     dten[rank==rnk, y:=y+y_parent]
#     dten[,x_parent:=NULL]
#     dten[,x_parent2:=NULL]
#     dten[,y_parent:=NULL]
#     dten[,y_parent2:=NULL]
# }
#
# plt = ggplot(dten[rank%in%lRanks[1:6]],
#        aes(xmin=x, ymin=y-h, ymax=y, xmax=x+w_pp, fill=domain, alpha=avg_maxpers1)) +
#     geom_rect() +
#     coord_polar(theta="x") +
#     theme_void()
#
# ggsave("pie.png", plt, width=10, height=10, dpi=300)

setorder(dten, -"proteins")

dten[, s:=avg_maxpers1_pp/avg_n]
# hist(dten$s)
# 6 bins
dten[, sBin:=pmin(floor(s*4/0.05), 6)/6]
dten[domain=="A", col:=hsv(  2/360, sBin, 1)]
dten[domain=="B", col:=hsv( 96/360, sBin, 1)]
dten[domain=="E", col:=hsv(196/360, sBin, 1)]
# dten[domain=="V", col:=hsv(309/360, s, 1)]

# add fake label nodes
# dten = rbind(dten,
#              dten[rank=="domain", .(id=label, parent=id, rank="label", label, r=4000)],
#              fill=TRUE
# )

# annotate parent rank
if("rank_parent"%in%names(dten)) {dten[, rank_parent:=NULL]}
dten = merge(dten, dten[,.(id,rank)], by.x="parent", by.y="id", all.x=TRUE, suffixes=c("", "_parent"))
dten[is.na(rank_parent), rank_parent:="origin"]

# set initial radii and then update them going up
dten[rank!="label", r:=0]
# for species, area == #proteins
dten[rank=="species", r:=sqrt(proteins/pi)]

# from bottom, iteratively require a minimum radius needed for parent
for (rnk in c(rev(lRanks[2:length(lRanks)-1]), "origin")) {
    cat(rnk, "\n")
    # pack children
    dten[rank_parent==rnk, c("x","y","r") := circlePack(r, 'radius'), by=parent]
    # set r to fit children
    dtt = dten[rank_parent==rnk, .(r=max(sqrt(x^2+y^2)+r)), by=parent]
    dten[dtt, on=c(id="parent"), r := pmax(r, i.r)] # r (not i.r) should always be zero actually
}

# rotate within each node so we can overlap domains and save space and for a more varied look.
rotB = pi/4
rotE = pi/3.5
rotA = pi/4

parents = lDomains
for(i in 1:99) {
    cat(i, "\n")
    # theta = custom overall domain rotation + 1/7 of a full rotation for each rank
    dten[parent%in%parents & domain=="B", c("x", "y") := rot(x, y, rotB)]
    dten[parent%in%parents & domain=="E", c("x", "y") := rot(x, y, rotE)]
    dten[parent%in%parents & domain=="A", c("x", "y") := rot(x, y, rotA)]
    rotB=rotB+2*pi/7
    rotE=rotE+2*pi/7
    rotA=rotA+2*pi/7
    # from top, place children inside parent node.
    dtt = merge(dten[parent%in%parents, .(id,x,y,r), by=parent],
                dten[id%in%parents, .(x, y, r), by=id], by.x="parent", by.y="id", suffixes=c("", "_parent"))
    if (nrow(dtt) == 0) break
    # 1D scaling factor is comparing parent diameter to current child span (largest range)
    dtt[, scl:=r_parent / max(sqrt(x^2+y^2)+r), by=parent]
    # scale down each axis and place relative to parent centre
    dtt = dtt[, .(id, x=x_parent + x*scl, y=y_parent + y*scl, r=r*scl)]
    # update values
    dten[dtt, on=.(id), c("x", "y", "r") := .(i.x, i.y, i.r)]
    parents = dtt$id
}

# move E to be below and slightly overlapping B
xyB = dten[id=="B", .(x,y)]
xyE = dten[id=="E", .(x,y)]
ErelB = (xyE - xyB)*.8
relB = xyB + rot(ErelB$x, ErelB$y, -pi/2.5) - xyE
dten[domain=="E", c("x", "y") := .(x, y) + relB]
# do the same for A relative to E
xyE = dten[id=="E", .(x,y)]
xyA = dten[id=="A", .(x,y)]
ArelE = (xyA - xyE)*.7
relE = xyE + rot(ArelE$x, ArelE$y, -pi/1.7) - xyA
dten[domain=="A", c("x", "y") := .(x, y) + relE]

# use outline as domain, instead of circle to save space
dtbg = merge(dten[rank_parent=="domain", .(domain=domain, rank="domain", id=paste("domain", id), x, y, r=r+1100)],
             dten[rank=="domain", .(domain, col)], by="domain") # add color with a merge
dten = rbind(dten[rank!="domain"], dtbg, fill=TRUE)
# if we are doing outline, then move domains into nicer locations
dten[domain=="E", x := x-5000]
dten[domain=="A", x := x-7500]

# zoom of homo sapiens
dtz = dten[label=="Homo sapiens"]
dtz[, c("id", "x", "y", "r") := .("zoom", 13000, -15000, 6000)]
dten = rbind(dten, dtz, fill=TRUE)

# build polygons
dtv = rbind(getVerts(dten[100 <= r]     , 160),
            getVerts(dten[(10 <= r) & (r < 100)], 40) ,
            getVerts(dten[(1 <= r ) & (r < 10 )], 16),
            getVerts(dten[r < 1]            ,   6))
dtp = merge(dtv, dten[, .(domain, rank, id, col, cor_nrep1_pp)], by="id")
cat(nrow(dtp), '\n')
setorder(dtp, "domain")

plt = ggplot(mapping=aes(x=x, y=y, group=id, fill=col, linewidth=rank, color=log(1-cor_nrep1_pp)))
plt=plt+
    geom_polygon(data=dtp[rank=="domain" & domain=="B"]) +
    geom_polygon(data=dtp[rank=="domain" & domain=="E"]) +
    geom_polygon(data=dtp[rank=="domain" & domain=="A"])
for (rnk in lRanks[2:length(lRanks)]) plt=plt+geom_polygon(data=dtp[rank==rnk])
plt=plt+
    annotate("text", label="Bacteria", x=-40000, y=24000, size=6, color=green, hjust=0) +
    annotate("text", label="Eukaryote", x=-40000, y=-26000, size=6, color=blue, hjust=0) +
    annotate("text", label="Archaea", x=1000, y=-35000, size=6, color=red, hjust=0) +
    # geom_text(data=dten[rank=="label"], mapping=aes(label=label, size=r), color="black") +
    scale_fill_identity() +
    scale_linewidth_manual(values=c(0., .3, .2, .1, .05, .025, 0.01, 0.005), breaks=lRanks, guide="none") +
    scale_color_gradient(low="black", high="yellow", guide="none") +
    coord_fixed() #+
    #theme_void()
plt

ggsave("pack_zoom.jpg", plt, width=210, height=297, units="mm", dpi=1000)

# TODO: rotate E so human is on the right.
# TODO: take 3 largest B phylum, calc gap location, add gap node to fill bg.

# maxCor = dten[!is.na(cor_nrep1_pp), max(1/cor_nrep1_pp-1)]
# clerp <- function (vals) {
#     vals = 1/vals-1
#     vals / max(vals)
#     # vals / maxCor
# }
# dten[, y:=as.numeric(rank)+clerp(cor_nrep1_pp), by=rank]
# dten[is.na(y), y:=as.numeric(rank)]
#
# dten[, alpha:=avg_maxpers1/max(avg_maxpers1)]
# dten[domain=="A", hue:=0/4]
# dten[domain=="B", hue:=1/4]
# dten[domain=="E", hue:=2/4]
# dten[domain=="V", hue:=3/4]
#
# plt = ggplot() + geom_scattermost(cbind(0,0), col="transparent")
# for(i in 1:length(lRanks)) {
#     dtenr = dten[rank==lRanks[i]]
#     plt=plt+ geom_scattermost(dtenr[, .(x+width/2,y-.5)], col=hsv(h=dtenr$hue, s=1, v=(dtenr$alpha+1)/2, alpha=0.5), pointsize=9-i, pixels=c(2000,2000))
# }
# plt + coord_polar() + theme_void()

# treemap(dtf=, index=lRanks[1:3], vSize="proteins", vColor="avg_maxpers1")
