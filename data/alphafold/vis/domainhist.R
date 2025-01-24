#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(ggplot2))
# install.packages("cowplot")
library(cowplot)
# install.packages("ggh4x")
library(ggh4x)

green = "#5fb12a"
blue  = "#267592"
red   = "#e23a34"

# convert from bucket in range [0,1000] to the actual value for richness.
bucket2richness = function(bucket) {
    # first the value in log10 space
    v = dt_maxs$richness_min + (bucket / 1000) * (dt_maxs[,richness_max - richness_min])
    10^v
}
# Version with formatting
bucket2richness.fmt = function(bucket) {
    format(bucket2richness(bucket), digits=3, scientific=TRUE)
}
# inverse of above without formatting
richness2bucket = function(v) {
    # first the value in log10 space
    1000 * (log10(v) - dt_maxs$richness_min) / (dt_maxs[,richness_max - richness_min])
}

# for subfig A we comp topological richness as a single value for each species.
dtn = fread("./taxNodes.tsv.gz")[domain!="V"]
dt.rich = dtn[rank=="species", .(richness=avg_nrep1_t10_pp/avg_n_pp, proteins), by=domain]
dt.rich[,weighted:=richness*proteins]

breaks = c(1e-5, 1e-4, 5e-4, 1e-3, 2e-3, 5e-3, 1e-2, 2e-2)
# trick to place similar space here as with other subplots that have facets
dt.rich[,H:=" "]
p.dens = ggplot(dt.rich, aes(richness, fill=domain, color=domain)) +
    scale_x_log10(
        name="Topological richness from species-averages",
        expand=c(0,0),
        limits=c(NA, 7.7e-2), # expand limits to better match with other subfigure
        breaks=breaks
    ) +
    scale_fill_manual(name="Domain", values=c(red, green, blue)) +
    scale_color_manual(name="Domain", values=c(red, green, blue)) +
    geom_density(alpha=0.3, show.legend=FALSE) +
    theme_minimal() +
    theme(
        panel.grid.minor=element_blank(),
        panel.grid.major.y=element_blank(),
        panel.border=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        axis.title.y=element_blank(),
        panel.spacing=unit(0, "lines"),
        legend.position="inside",
        legend.position.inside=c(0.9, 1.1)
    ) +
    guides(color=guide_legend(override.aes=list(linewidth=1))) +
    facet_grid(rows=vars(H), scales="free_y")
p.dens

# how many are discarded from having 0 richness
dt.rich.0 = merge(
    dt.rich[richness==0, .(n.prots.discarded=sum(proteins), n.species.discarded=.N), by=domain],
    dt.rich[, .(n.prots.total=sum(proteins), n.species.total=.N), by=domain],
    by="domain"
)
dt.rich.0[,frac.prots.discarded:=n.prots.discarded/n.prots.total]
dt.rich.0[,frac.species.discarded:=n.species.discarded/n.species.total]
dt.rich.0

dt_maxs = fread("../postgres/domainhistmaxs.csv")
dt = fread("../postgres/domainhist.csv")[domain!="V"]
setnames(dt, "h", "H")
# One NA bucket for each species which counts of how many entries had richness=0 since we couldn't do log10(0).
# we temp use bucket -1 for these.
# buckets are otherwise in range [1,1001] which corresponds to values in [0, dt_maxs$<NAME>]
range(dt[!is.na(bucket),bucket])
dt[!is.na(bucket), bucket:=bucket-1]
dt[is.na(bucket),bucket:=-1]

# any bucket without values will be missing but should have freq=0, and weighted=0
buckets = CJ(bucket=0:1000, H=unique(dt$H), domain=unique(dt$domain), meas=unique(dt$meas))
dt = merge(dt, buckets, by=c("H", "domain", "meas", "bucket"), all=TRUE)[!((meas=="richness") & (H==2))]
dt[is.na(dt)] = 0
dt = dt[order(bucket)]

# domain average
dt[bucket!=-1, richness:=bucket2richness(bucket)]
dt[bucket==-1, richness:=0]
dt[meas=="richness", .(richness.avg=sum(richness*freq)/sum(freq)), by=domain]

# this table shows how many are discarded from having 0 richness
dt.0 = merge(
    dt[bucket==-1,.(domain,n.prots.discarded=freq,weighted)],
    dt[meas=="richness",.(n.prots.total=sum(freq), n.species.total=sum(weighted)),by=domain],
    by="domain"
)
dt.0[,frac.prots.discarded:=n.prots.discarded/n.prots.total]
dt.0
dt = dt[bucket!=-1]

# coarsen hists
w_rich = 7
w_nrep = 3
w_maxrep = 5
dt[meas=="richness",xmin:=floor(bucket/w_rich)*w_rich]
dt[meas=="nrep",    xmin:=floor(bucket/w_nrep)*w_nrep]
dt[meas=="maxrep",  xmin:=floor(bucket/w_maxrep)*w_maxrep]
dt = dt[, .(freq=sum(freq), weighted=sum(weighted)), by=c("domain", "xmin", "H", "meas")]

# scale to sum to 1 like a density
dt[, dens:=freq/sum(freq), by=c("domain", "H", "meas")]
dt[, densw:=weighted/sum(weighted), by=c("domain", "H", "meas")]

# preserve a copy
dt.rich.plt = dt[meas=="richness"]

# scale buckets out of 1000 to actual range of values.
# First calc 4 scaling ratios and temporarily store to w
dt[(meas=="nrep")  &(H==1), w:=dt_maxs$nrep1_max    /1000]
dt[(meas=="nrep")  &(H==2), w:=dt_maxs$nrep2_max    /1000]
dt[(meas=="maxrep")&(H==1), w:=dt_maxs$maxrep1_max  /1000]
dt[(meas=="maxrep")&(H==2), w:=dt_maxs$maxrep2_max  /1000]
# scale xmin
dt[,xmin:=w*xmin]
# then actually set the scaled bin width
dt[meas=="nrep",    w:=w*w_nrep]
dt[meas=="maxrep",  w:=w*w_maxrep]

# Display names
dt[domain=="B", domain:="Bacteria"]
dt[domain=="A", domain:="Archaea"]
dt[domain=="E", domain:="Eukaryota"]

dt[,H:=as.character(H)]
dt[H=="1", H:="Loops"]
dt[H=="2", H:="Voids"]

# trick to place similar space here as with other subplots that have facets
dt.rich.plt[,H:=as.character(H)]; dt.rich.plt[,H:=" "]
p.rich = ggplot(dt.rich.plt, aes(
    fill=domain,
    xmin=xmin, xmax=xmin+w_rich, ymax=densw,
    x=xmin, y=densw
)) +
    scale_x_continuous(
        name="Topological richness from individual proteins",
        expand=c(0,0),
        label=bucket2richness.fmt,
        breaks=richness2bucket(breaks)
    ) +
    scale_fill_manual(name="Domain", values=c(red, green, blue)) +
    scale_color_manual(name="Domain", values=c(red, green, blue)) +
    geom_rect(ymin=0, alpha=0.3, position="identity", show.legend=FALSE) +
    geom_step(
        mapping=aes(color=domain),
        direction="hv",
        position="identity",
        linewidth=.2,
        show.legend=FALSE
    ) +
    theme_minimal() +
    theme(
        panel.grid.minor=element_blank(),
        panel.grid.major.y=element_blank(),
        panel.border=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        axis.title.y=element_blank(),
        panel.spacing=unit(0, "lines"),
        legend.position="inside",
        legend.position.inside=c(0.9, 1.1)
    ) +
    guides(color=guide_legend(override.aes=list(linewidth=1))) +
    # disable clipping since a tiny bit of the plot outline from geom_step is cut by the clipping mask.
    coord_cartesian(clip="off") +
    facet_grid(rows=vars(H), scales="free_y")
p.rich

plt_common = function(show.legend, measname, xname) {
    ggplot(dt[meas==measname], aes(
        fill=domain,
        xmin=xmin, xmax=xmin+w, ymax=densw,
        x=xmin, y=densw
    )) +
    scale_x_continuous(name=xname, expand=c(0,0)) +
    facet_grid(rows=vars(H), scales="free_y") +
    # from ggh4x
    facetted_pos_scales(y=list(
        scale_y_continuous(expand=expansion(mult=c(0,0))),
        scale_y_reverse(   expand=expansion(mult=c(0,0)))
        # An alternative to disabling clipping:
        # scale_y_continuous(expand=expansion(mult=c(0,4e-3))),
        # scale_y_reverse(   expand=expansion(mult=c(4e-3,0)))
    )) +
    scale_fill_manual(name="Domain", values=c(red, green, blue)) +
    scale_color_manual(name="Domain", values=c(red, green, blue)) +
    geom_rect(ymin=0, alpha=0.3, position="identity", show.legend=FALSE) +
    geom_step(
        mapping=aes(color=domain),
        direction="hv",
        position="identity",
        linewidth=.2,
        show.legend=show.legend
    ) +
    theme_minimal() +
    theme(
        panel.grid.minor=element_blank(),
        panel.grid.major.y=element_blank(),
        panel.border=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        axis.title.y=element_blank(),
        panel.spacing=unit(0, "lines"),
        legend.position="inside",
        legend.position.inside=c(0.9, 1.1)
    ) +
    guides(color=guide_legend(override.aes=list(linewidth=1))) +
    # disable clipping since a tiny bit of the plot outline from geom_step is cut by the clipping mask.
    coord_cartesian(clip="off")
}

p = plot_grid(
    p.dens,
    p.rich,
    plt_common(F, "nrep",     "Representatives per residue"),
    plt_common(T, "maxrep",   "Max simplices per residue"),
    labels="AUTO",
    ncol=1
)
p

# ggsave("domainhist.pdf", p, width=13, height=6)
# install.packages("svglite")
# ggsave("domainhist.svg", p, width=13, height=6)





