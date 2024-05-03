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

dt = fread("./taxNodes.tsv.gz", sep='\t')
dt = dt[domain != "V"]

dt = melt(dt[rank=="species"], c(
    "id",
    "domain",
    "type",
    "proteins",
    "proteins_pp",
    "rank",
    "label",
    "avg_n",
    "avg_n_pp"
), variable.name="variable", value.name="value")

dtp = data.table()
for(H in 1:2) {
    for(meas in c("nrep", "maxrep", "maxpers")) {
        dtt = dt[variable==paste0("avg_", meas, H, "_pp")]
        dtt$measure = meas
        dtt$H = paste0("H", H)
        dtp = rbind(dtp, dtt)
    }
}

# full name for display
dtp[domain=="B", domain:="Bacteria"]
dtp[domain=="A", domain:="Archaea"]
dtp[domain=="E", domain:="Eukaryota"]

p_nrep = ggplot(dtp[measure=="nrep"], aes(x=value/avg_n_pp, fill=domain, color=domain)) +
    scale_x_continuous(expand=c(0,0), name="Representatives per residue")
    # geom_col(data=dtm[measure=="nrep"], aes(y=y), width=0.002, color=NA, position="identity") +
    # geom_text(data=dtm[measure=="nrep"], aes(label=abb, y=y), vjust=-.1, show.legend=FALSE)

p_maxrep = ggplot(dtp[measure=="maxrep"], aes(x=value/avg_n_pp, fill=domain, color=domain)) +
    scale_x_continuous(limits=c(0,1), expand=c(0,0), name="Proportion of residues in the largest representative")
    # geom_col(data=dtm[measure=="maxrep"], aes(y=y), width=0.002/dtp[,max(value/avg_n_pp)], color=NA, position="identity") +
    # geom_text(data=dtm[measure=="maxrep"], aes(label=abb, y=y), vjust=-.1, show.legend=FALSE)

plt_common = function (p, flip=FALSE) {
    p = p + facet_grid(rows=vars(H), scales="free_y")
    # from ggh4x
    if(flip) {
        p=p+ facetted_pos_scales(y=list(
            scale_y_continuous(expand=expansion(mult=c(0,0))),
            scale_y_reverse(expand=expansion(mult=c(0,0)))
        ))
    }
    p +
    scale_fill_manual(name="Domain", values=c(red, green, blue)) +
    scale_color_manual(name="Domain", values=c(red, green, blue)) +
    geom_density(alpha=0.3) +
    # geom_histogram(alpha=0.3, position="identity", bins=1000) +
    theme_minimal() +
    theme(
        panel.grid.minor=element_blank(),
        panel.grid.major.y=element_blank(),
        panel.border=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        axis.title.y=element_blank(),
        panel.spacing=unit(0, "lines")
    )
}

p = plot_grid(plt_common(p_nrep), plt_common(p_maxrep), labels="AUTO", ncol=1)
# p = plot_grid(plt_common(p_nrep, TRUE), plt_common(p_maxrep, TRUE), labels="AUTO", ncol=1)
# ggsave("densFlip.pdf", p, width=14, height=7)
ggsave("dens.pdf", p, width=14, height=7)





