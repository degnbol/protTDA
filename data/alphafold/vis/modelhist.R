#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(ggplot2))
# install.packages("cowplot")
library(cowplot)
# install.packages("ggh4x")
library(ggh4x)

domain2col = c(
    B = "#5fb12a",
    E = "#267592",
    A = "#e23a34" 
)

dt = fread("../postgres/modelshist.csv.gz")
dt_maxs = fread("../postgres/domainhistmaxs.csv")
setnames(dt, "h", "H")
# buckets are in range [1,1001] which corresponds to values in [0, dt_maxs$<NAME>]
range(dt$bucket)
dt[, bucket:=bucket-1]

# add zero entries so all bins exist
dt0 = CJ(label=unique(dt$label), bucket=0:1000, H=1:2, meas=c("nrep", "maxrep"), freq=0, weighted=0)
dt0 = unique(dt[,.(label,tax,domain)])[dt0, on="label"]
dt = rbind(dt, dt0)

# coarsen hists
w_nrep = 3
w_maxrep = 5
dt[meas=="nrep",   xmin:=floor(bucket/w_nrep)*w_nrep]
dt[meas=="maxrep", xmin:=floor(bucket/w_maxrep)*w_maxrep]
dt = dt[, .(freq=sum(freq), weighted=sum(weighted)), by=c("label", "tax", "domain", "xmin", "H", "meas")]

# scale to sum to 1 like a density
dt[, dens:=freq/sum(freq), by=c("label", "tax", "domain", "H", "meas")]
# dt[, densw:=weighted/sum(weighted), by=c("label", "tax", "domain", "H", "meas")]

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

plt_common = function(measname, taxname) {
    xmax = dt[(meas==measname), max(xmin+w)]
    dtp = dt[(meas==measname)&(tax==taxname)]
    color = domain2col[unique(dtp$domain)]
    ggplot(dtp, aes(
        fill=domain,
        xmin=xmin, xmax=xmin+w, ymax=dens,
        x=xmin, y=dens
    )) +
    scale_x_continuous(expand=c(0,0), limits=c(0,xmax)) +
    facet_grid(rows=vars(H), scales="free_y") +
    # from ggh4x
    facetted_pos_scales(y=list(
        scale_y_continuous(expand=expansion(mult=c(0,0))),
        scale_y_reverse(   expand=expansion(mult=c(0,0)))
        # An alternative to disabling clipping:
        # scale_y_continuous(expand=expansion(mult=c(0,4e-3))),
        # scale_y_reverse(   expand=expansion(mult=c(4e-3,0)))
    )) +
    scale_fill_manual(values=color) +
    scale_color_manual(values=color) +
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
        panel.grid.major=element_blank(),
        panel.border=element_blank(),
        axis.text=element_blank(),
        axis.ticks=element_blank(),
        axis.title=element_blank(),
        panel.spacing=unit(0, "lines"),
        strip.text=element_blank()
    ) +
    guides(color=guide_legend(override.aes=list(linewidth=1))) +
    # disable clipping since a tiny bit of the plot outline from geom_step is cut by the clipping mask.
    coord_cartesian(clip="off")
}

for(tax in unique(dt$tax)) {
    p_nrep   = plt_common("nrep",   tax)
    p_maxrep = plt_common("maxrep", tax)
    ggsave(paste0("models/nrep-",   tax, ".pdf"), p_nrep,   width=3, height=1)
    ggsave(paste0("models/maxrep-", tax, ".pdf"), p_maxrep, width=3, height=1)
}


dtn = fread("./taxNodes.tsv.gz", sep='\t')
dtn = dtn[label%in%unique(dt$label)]

# https://www.statology.org/histogram-standard-deviation/
dt[, avg:=sum((xmin+unique(w)/2)*dens), by=c("label", "tax", "domain", "H", "meas")]
dt[, std:=sqrt(sum(freq*(xmin+unique(w)/2 - avg)^2) / (.N-1)), by=c("label", "tax", "domain", "H", "meas")]
dt[, err:=std / sqrt(.N), by=c("label", "tax", "domain", "H", "meas")]
dt = unique(dt[, sprintf("%.2f$\\pm$%.2f", avg, err), by=c("label", "domain", "H", "meas")])

# write latex table
dtt = data.table()
dtt$label = dtn$label
dtt$Proteins = dtn$proteins_pp
dtt$Residues = dtn[,sprintf("%.2f$\\pm$%.2f", avg_n_pp, sqrt(var_n_pp))]
dtt$A = paste0("\\includegraphics[width=\\linewidth]{./figures/models/nrep-", dtn$id, ".pdf}")
dtt$B = paste0("\\includegraphics[width=\\linewidth]{./figures/models/maxrep-", dtn$id, ".pdf}")

dt_nrep1   = dt[(meas=="nrep")&(H==1)  , .(label, `\\makecell[r]{Loops\\\\/res}`=V1)]
dt_nrep2   = dt[(meas=="nrep")&(H==2)  , .(label, `\\makecell[r]{Voids\\\\/res}`=V1)]
dt_maxrep1 = dt[(meas=="maxrep")&(H==1), .(label, `\\makecell[r]{Largest loop\\\\/res}`=V1)]
dt_maxrep2 = dt[(meas=="maxrep")&(H==2), .(label, `\\makecell[r]{Largest void\\\\/res}`=V1)]

dtt = dtt[dt_nrep1, on="label"][dt_nrep2, on="label"][dt_maxrep1, on="label"][dt_maxrep2, on="label"]

setnames(dtt, "label", "Organism")
setcolorder(dtt, c(names(dtt)[1:4], names(dtt)[6:7], "B", names(dtt)[8:9]))
dtt = dtt[order(rank(Organism))]

lines = c(
"\\begin{table}[ht]",
"	\\caption{",
"		\\textbf{Model organism distributions.}",
"		Proteins = Number of protein structures predicted by AlphaFold2.",
"		Residues = Average and stddev. of protein chain length.",
"		Loops/res = Average and std. err. for number of loops divided by protein chain length.",
"		Voids/res = Same as loops.",
"		Largest loop/res = Average and std. err. for max. number of loop simplices divided by protein chain length.",
"		Largest void/res = Same as loops.",
"		Charts A and B depict species-wise distributions for comparisons to Fig. 2A and B, respectively.",
"	}",
"	\\scriptsize",
"	\\begin{tabularx}{\\textwidth}{@{}lrrYrrYrr@{}}",
"\\toprule")
lines = c(lines,
    paste(paste(names(dtt), collapse=" & "), "\\\\"),
    "\\midrule"
)
for(i in 1:nrow(dtt)) {
    lines = c(lines, paste(paste(dtt[i], collapse=" & "), "\\\\"))
}
lines = c(
    lines,
"\\bottomrule",
"	\\end{tabularx}",
"\\end{table}"
)

fh = file("modelOrganisms.tex")
writeLines(lines, fh)
close(fh)


