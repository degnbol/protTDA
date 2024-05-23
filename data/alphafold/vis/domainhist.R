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

dt = fread("../postgres/domainhist.csv")
dt_maxs = fread("../postgres/domainhistmaxs.csv")
setnames(dt, "h", "H")
# buckets are in range [1,1001] which corresponds to values in [0, dt_maxs$<NAME>]
range(dt$bucket)
dt[, bucket:=bucket-1]

# coarsen hists
w_nrep = 3
w_maxrep = 5
dt[meas=="nrep",   xmin:=floor(bucket/w_nrep)*w_nrep]
dt[meas=="maxrep", xmin:=floor(bucket/w_maxrep)*w_maxrep]
dt = dt[, .(freq=sum(freq), weighted=sum(weighted)), by=c("domain", "xmin", "H", "meas")]

# scale to sum to 1 like a density
dt[, dens:=freq/sum(freq), by=c("domain", "H", "meas")]
dt[, densw:=weighted/sum(weighted), by=c("domain", "H", "meas")]

# scale buckets out of 1000 to actual range of values.
# First calc 4 scaling ratios and temporarily store to w
dt[(meas=="nrep")  &(H==1), w:=dt_maxs$nrep1_max  /1000]
dt[(meas=="nrep")  &(H==2), w:=dt_maxs$nrep2_max  /1000]
dt[(meas=="maxrep")&(H==1), w:=dt_maxs$maxrep1_max/1000]
dt[(meas=="maxrep")&(H==2), w:=dt_maxs$maxrep2_max/1000]
# scale xmin
dt[,xmin:=w*xmin]
# then actually set the scaled bin width
dt[meas=="nrep",  w:=w*w_nrep]
dt[meas=="maxrep",w:=w*w_maxrep]

# Display names
dt[domain=="B", domain:="Bacteria"]
dt[domain=="A", domain:="Archaea"]
dt[domain=="E", domain:="Eukaryota"]
dt = dt[domain!="V"]

dt[,H:=as.character(H)]
dt[H=="1", H:="Loops"]
dt[H=="2", H:="Voids"]

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
    plt_common(F, "nrep",   "Representatives per residue"),
    plt_common(T, "maxrep", "Max simplices per residue"),
    labels="AUTO",
    ncol=1
)
ggsave("domainhist.pdf", p, width=13, height=6)
# install.packages("svglite")
ggsave("domainhist.svg", p, width=13, height=6)





