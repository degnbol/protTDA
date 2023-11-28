#!/usr/bin/env Rscript
library(data.table)
library(ggplot2)

dt = fread("thermozymes-acc-unjag-summ.tsv.gz")
dt$thermophile = factor(dt$thermophile)
dt = dt[pers2 > .5]

# balance
dtb = dt[thermophile==1]
for(ec in unique(dt$EC)) {
    n = nrow(dtb[EC==ec])
    dtm = dt[(thermophile == 0) & (EC==ec)][sample(.N, n, replace=TRUE)]
    dtb = rbind(dtb, dtm)
}
# validate my code:
# dtb[,.N,by=.(thermophile, EC)][order(EC)]


# we can avoid overlap in visuals by mirroring one of the persistence diagrams
dtb[thermophile==0, c("death2", "birth2") := list(birth2, death2)]

for(ec in unique(dtb$EC)) {
    dte = dtb[EC == ec]
    ggplot(dte, aes(x=birth2, y=death2, color=thermophile)) +
        facet_wrap("acc") +
        scale_color_manual(values=c("blue", "red")) +
        geom_abline(slope=1, intercept=0, color="gray") +
        geom_point(alpha=0.5, size=0.5) +
        coord_fixed() +
        ggtitle(ec)
    ggsave(paste0("diag_", ec, ".pdf"), width=15, height=15)
}


ggplot(dtb, aes(x=birth2, y=death2, color=thermophile)) +
    facet_wrap("EC") +
    scale_color_manual(values=c("blue", "red")) +
    geom_abline(slope=1, intercept=0, color="gray") +
    geom_point(alpha=0.05, size=0.5) +
    coord_fixed()

ggsave("persistenceDiagramsH2.pdf")

ggplot(dtb, aes(x=birth2, y=death2, color=thermophile, alpha=pers2, size=nRep2)) +
    facet_wrap("EC") +
    scale_color_manual(values=c("blue", "red")) +
    scale_alpha_continuous(range=c(0, 0.1)) +
    scale_size_continuous(range=c(0, 2)) +
    geom_abline(slope=1, intercept=0, color="gray") +
    geom_point() +
    coord_fixed()

ggsave("persistenceDiagramsH2_nRep2.pdf")

ggplot(dtb, aes(x=nRep2, y=pers2, color=thermophile)) +
    facet_wrap("EC") +
    scale_color_manual(values=c("blue", "red")) +
    geom_point(alpha=0.05, size=0.5)

ggsave("nRep2_pers2.pdf")
