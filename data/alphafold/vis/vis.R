#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(ggplot2))
library(geomtextpath)
suppressPackageStartupMessages(library(data.table))
library(packcircles)
library(graphics)
# library(ggchromatic)
library(ggnewscale)

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

# Calc outer tangent xys given a smaller and a larger circle (in that order).
# https://en.wikipedia.org/wiki/Tangent_lines_to_circles#Outer_tangent
outerTangents = function(x1, y1, x2, y2, r, R) {
    gamma = -atan((y2 - y1) / (x2 - x1))
    beta  = asin((R-r) / sqrt((x2-x1)^2 + (y2-y1)^2))
    beta  = c(beta, -beta)
    alpha = gamma - beta
    data.table(x=c(x1+r*sin(alpha[1]), x2+R*sin(alpha[1]), x2-R*sin(alpha[2]), x1-r*sin(alpha[2])),
               y=c(y1+r*cos(alpha[1]), y2+R*cos(alpha[1]), y2-R*cos(alpha[2]), y1-r*cos(alpha[2])))
}
# sometimes one works and not the other, I'm sure there's a smarter way to choose signs on beta but alas.
outerTangents2 = function(x1, y1, x2, y2, r, R) {
    gamma = -atan((y2 - y1) / (x2 - x1))
    beta  = asin((R-r) / sqrt((x2-x1)^2 + (y2-y1)^2))
    beta  = c(-beta, beta)
    alpha = gamma - beta
    data.table(x=c(x1+r*sin(alpha[1]), x2+R*sin(alpha[1]), x2-R*sin(alpha[2]), x1-r*sin(alpha[2])),
               y=c(y1+r*cos(alpha[1]), y2+R*cos(alpha[1]), y2-R*cos(alpha[2]), y1-r*cos(alpha[2])))
}

dtn = fread("./taxNodes.tsv.gz")
dte = fread("./taxEdges.tsv.gz")
dt.human = fread("./human.tsv.gz")
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

# recalc avg_maxpers1_pp
dten[, prots := 0]
dten[, maxpers1_pp := 0]
dten[rank=="species", prots := proteins]
dten[rank=="species", maxpers1_pp := avg_maxpers1_pp * prots]
ids = dten[rank=="species", id]
for(i in 1:99) {
    cat(i, '\n')
    dtt = dten[id%in%ids, .(prots=sum(prots), maxpers1_pp=sum(maxpers1_pp)), by=parent]
    if(nrow(dtt) == 0) break
    dten[dtt, on=c(id="parent"), c("prots", "maxpers1_pp") := .(prots+i.prots, maxpers1_pp+i.maxpers1_pp)]
    ids = dtt$parent
}
# dten[rank!="species", avg_maxpers1_pp := maxpers1_pp/prots]

setorder(dten, -"proteins")

dten[, s:=avg_maxpers1_pp/avg_n]
# hist(dten$s)
# 6 bins
dten[, sBin:=pmin(floor(s*4/0.05), 6)/6]
dten[domain=="A", col:=hsv(  2/360, sBin, 1)]
dten[domain=="B", col:=hsv( 96/360, sBin, 1)]
dten[domain=="E", col:=hsv(196/360, sBin, 1)]
# dten[domain=="V", col:=hsv(309/360, s, 1)]

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
rotE = pi*1.28
rotA = pi/4

parents = lDomains
for(i in 1:99) {
    cat(i, "\n")
    # theta = custom overall domain rotation + 1/7 of a full rotation for each rank
    # rotation is counter-clockwise here
    dten[parent%in%parents & domain=="B", c("x", "y") := rot(x, y, rotB)]
    dten[parent%in%parents & domain=="E", c("x", "y") := rot(x, y, rotE)]
    dten[parent%in%parents & domain=="A", c("x", "y") := rot(x, y, rotA)]
    # custom rotations of Mammalia, Primates related to the zoom on human
    # and Ascomycota related to showing yeast
    dten[parent%in%parents & parent=="40674", c("x", "y") := rot(x, y, pi)]
    dten[parent%in%parents & parent=="9443", c("x", "y") := rot(x, y, pi*.75)]
    dten[parent%in%parents & parent=="9404", c("x", "y") := rot(x, y, pi)]
    dten[parent%in%parents & parent=="4890", c("x", "y") := rot(x, y, pi/2)] # Ascomycota
    dten[parent%in%parents & parent=="1236", c("x", "y") := rot(x, y, -pi*.55)] # Gammaproteobacteria
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
dtbg = dten[rank_parent=="domain", .(domain=domain, rank="domain", id=paste("domain", id), x, y, r=r+1100)]
# add fake nodes to fill gaps in bacteria outline
dtbg = rbind(dtbg, data.table(domain="B", rank="domain", id=c("gap1", "gap2"), x=c(-10000, -15000), y=c(1000, 10000), r=3000))
# add color with a merge
dtbg = merge(dtbg, dten[rank=="domain", .(domain, col)], by="domain")
# add everything that is not outline
dtbg = rbind(dten[rank!="domain"], dtbg, fill=TRUE)
# move domains into nicer locations
dtbg[domain=="E", x := x-7000]
dtbg[domain=="E", y := y+1600]
dtbg[domain=="A", x := x-7300]

# zoom of homo sapiens
dths = dtbg[id=="9606"]
dtz = copy(dths)
dtz[, c("id", "x", "y", "r") := .("zoom", 9000, -17500, 6000)]
dtbg = rbind(dtbg[id!="zoom"], dtz, fill=TRUE)
# zoom rect (not quite a rectangle) showing shaded area from human node to zoomed version.
zoom.rect = outerTangents(dths$x, dths$y, dtz$x, dtz$y, dths$r, dtz$r)

# circle pack zoom of proteins
dt.prot = cbind(dt.human, circlePack(dt.human$n, "area"))
# rotate to get a nicer heme zoom cone (no cone-cone overlap)
dt.prot[, c("x", "y") := rot(x, y, pi*.28)]
# scale and place
scl.prot = dtz$r / dt.prot[, max(sqrt(x^2+y^2)+r)]
dt.prot[, c("x", "y", "r") := .(x*scl.prot + dtz$x, y*scl.prot + dtz$y, r*scl.prot)]
dt.prot[, s:=maxpers1/n]
# hist(dt.prot$s)
# 6 bins exactly like for the averaged nodes
dt.prot[, sBin:=pmin(floor(s*4/0.05), 6)/6]
dt.prot[, col:=hsv(196/360, sBin, 1)]
dtbg = rbind(dtbg[rank!="protein"], dt.prot[, .(id=acc, x, y, r, col, rank="protein")], fill=TRUE)

# further zoom on hemoglobin subunit alpha
dt.heme = dt.prot[acc=="P69905"]
dtz2 = copy(dt.heme)
dtz2[, c("id", "x", "y", "r") := .("zoom2", 12500, -29000, 4000)]
dtbg = rbind(dtbg[id!="zoom2"], dtz2, fill=TRUE)
# zoom rect (not quite a rectangle) showing shaded area from zoom node to heme zoom.
zoom.rect2 = outerTangents(dt.heme$x, dt.heme$y, dtz2$x, dtz2$y, dt.heme$r, dtz2$r)


# build polygons
dtv = rbind(getVerts(dtbg[100 <= r]     , 160),
            getVerts(dtbg[(10 <= r) & (r < 100)], 40)   ,#)#,
            getVerts(dtbg[(1 <= r ) & (r < 10 )], 16)  ,#)#,
            getVerts(dtbg[r < 1]            ,   6))
dtp = merge(dtv, dtbg[, .(domain, rank, id, col, cor_nrep1_pp)], by="id")
cat(nrow(dtp), '\n')
setorder(dtp, "domain")

dt.lab = dtbg[(rank%in%lRanks[2:4] & r>2000) | (label%in%c("Nematoda")), .(id, domain, x, y, r, label, rot=0, vjust=1.1, fontface="plain")]
# add homo sapiens
dt.lab = rbind(dt.lab, dtbg[label=="Homo sapiens", .(id, domain, x=dtz$x, y=dtz$y, r=dtz$r, label, rot=0, vjust=1.2, fontface="italic")])
# add heme
dt.lab = rbind(dt.lab, dtz2[, .(id, domain="E", x, y, r, label="Hemoglobin subunit alpha", rot=pi, vjust=1.2, fontface="plain")])
# textcolor
dt.lab[domain=="B", col:=green]
dt.lab[domain=="E", col:=blue]
dt.lab[domain=="A", col:=red]
# custom rotations. 0 is up, values are clockwise radians.
dt.lab[domain=="A", rot:=pi]
dt.lab.rot = c(
    "Fungi",               -3/4 ,
    "Pseudomonadota",      -1/2 ,
    "Planctomycetota",     .35  ,
    "Clostridia",          -.6  ,
    "Bacilli",             -1/2 ,
    "Alphaproteobacteria", -.57 ,
    "Betaproteobacteria",  1/4  ,
    "Gammaproteobacteria", .6   ,
    "Ascomycota",          .53  ,
    "Bacillota",           1/3  ,
    "Nematoda",            -2/3 ,
    "Flavobacteriia",      -.45  ,
    "Actinomycetes",       -1/3 ,
    "Mammalia",             1 ,
    "Aves",                 1/4 ,
    "Insecta",              1/4 ,
    "Chordata",            -.55 
)
dt.lab.rot = data.table(label=dt.lab.rot[seq(1, length(dt.lab.rot), by=2)],
                        rot  =pi*as.numeric(dt.lab.rot[seq(2, length(dt.lab.rot), by=2)]))
dt.lab[dt.lab.rot, on="label", rot := i.rot]
dt.lab[label=="Bacteroidota",   c("rot", "vjust") := .(pi/ 3, 0)]
dt.lab[label=="Actinomycetota", c("rot", "vjust") := .(pi*.3, 0)]
# filter out labels if there is no space
dt.lab = dt.lab[!label%in%c("Streptophyta", "Arthropoda", "Cyanophyceae", "Bacteroidia", "Magnoliopsida", "Actinomycetes")]
# shorten some label names
dt.lab[label=="Flavobacteriia",  label:="Flavo-"]
dt.lab[label=="Cyanobacteriota", label:="Cyano-"]
dt.lab[label=="Planctomycetota", label:="Plancto-"]
# calc curve ends
dt.lab[, x1:=x+r*sin(rot+pi/2)]
dt.lab[, x2:=x+r*sin(rot-pi/2)]
dt.lab[, y1:=y+r*cos(rot+pi/2)]
dt.lab[, y2:=y+r*cos(rot-pi/2)]

# add some labels for species of interest
soi = c("Escherichia coli", "Saccharomyces cerevisiae", "Pyrococcus furiosus")
dt.species = dtbg[label%in%soi]
dt.species[, c("x2", "y2") := .(x, y)]
# sort
setkey(dt.species, "label")
dt.species = dt.species[soi]
dt.species$x   = c(-29000, -27000,    500)
dt.species$y   = c(-20000, -31000, -43000)
dt.species$gap = c(.18, .3, .39)
dt.species[, c("x1", "y1") := .(x*(1-gap)+x2*gap, y*(1-gap)+y2*gap)]
dt.species[, label:=sub(" ", "\n", label)]

plt = ggplot(mapping=aes(x=x, y=y))
# draw domain outline
plt=plt+ geom_polygon(data=dtp[rank=="domain"], mapping=aes(fill=col, group=id))
for (rnk in lRanks[2:8]) plt=plt+geom_polygon(data=dtp[rank==rnk], mapping=aes(fill=col, group=id, linewidth=rank, color=log(1-cor_nrep1_pp)))
plt=plt+geom_polygon(data=zoom.rect, fill=blue, alpha=0.3)
# if we use zoom shadow, then we need to draw human on top
plt=plt+geom_polygon(data=dtp[id%in%c(dths$id, "zoom")], mapping=aes(fill=col, group=id))
plt=plt+geom_polygon(data=dtp[rank=="protein"], mapping=aes(fill=col, group=id))
plt=plt+geom_polygon(data=zoom.rect2, fill=blue, alpha=0.3)
plt=plt+geom_polygon(data=dtp[id%in%c(dt.heme$acc, "zoom2")], mapping=aes(fill=col, group=id))
plt=plt+geom_textcurve(data=dt.lab, mapping=aes(label=label, x=x1, y=y1, xend=x2, yend=y2, textcolor=col, vjust=vjust, fontface=fontface), ncp=10, curvature=1, text_only=TRUE, size=2.8)
plt=plt+
    annotate("text", label="Bacteria",  x=-30200, y= 12000, size=6, color=green, hjust=1) +
    annotate("text", label="Eukaryota", x=-25500, y=-26000, size=6, color=blue,  hjust=1) +
    annotate("text", label="Archaea",   x=-11000, y=-44000, size=6, color=red,   hjust=1) +
    # annotate("text", label="Homo sapiens", x=dtz$x, y=dtz$y-dtz$r-1000, size=3.5, color=blue, fontface="italic") +
    scale_fill_identity() +
    scale_linewidth_manual(values=c(0., .3, .2, .1, .05, .025, 0.01, 0.0025), breaks=lRanks, guide="none") +
    scale_color_gradient(low="black", high="yellow", guide="none") +
    new_scale_color() +
    geom_segment(data=dt.species, mapping=aes(x=x1, y=y1, xend=x2, yend=y2), linewidth=0.2, linetype="dotted") +
    geom_text(data=dt.species, mapping=aes(label=label, color=domain), size=2.8, lineheight=.75, fontface="italic") +
    scale_color_manual(values=c(green, blue, red), guide="none") +
    coord_fixed() +theme_void()
# plt

ggsave("pack_lab.png", plt, width=210, height=297, units="mm", dpi=1000)

# TODO: rotate the whole thing a bit to reduce wasted space on the left. Place zooms under, going up.

