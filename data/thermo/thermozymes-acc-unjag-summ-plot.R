#!/usr/bin/env Rscript
library(data.table)
library(ggplot2)

dt = fread("thermozymes-acc-unjag-summ.tsv.gz")
dt$thermophile = factor(dt$thermophile)
dt = dt[pers2 > 1.]

# balance
dtb = dt[thermophile==1]
for(ec in unique(dt$EC)) {
    n = nrow(dtb[EC==ec])
    dtm = dt[(thermophile == 0) & (EC==ec)][sample(.N, n, replace=TRUE)]
    dtb = rbind(dtb, dtm)
}
# validate my code:
# dtb[,.N,by=.(thermophile, EC)][order(EC)]

ggplot(dtb, aes(x=birth2, y=death2, color=thermophile)) +
    facet_wrap("EC") +
    scale_color_manual(values=c("blue", "red")) +
    geom_point(alpha=0.05, size=0.5)

ggsave("persistenceDiagramsH2.pdf")

ggplot(dtb, aes(x=nRep2, y=pers2, color=thermophile)) +
    facet_wrap("EC") +
    scale_color_manual(values=c("blue", "red")) +
    geom_point(alpha=0.05, size=0.5)

ggsave("nRep2_pers2.pdf")

ggplot(dtb, aes(x=birth2, y=death2, color=thermophile, alpha=pers2, size=nRep2)) +
    facet_wrap("EC") +
    scale_color_manual(values=c("blue", "red")) +
    scale_alpha_continuous(range=c(0, 0.1)) +
    scale_size_continuous(range=c(0, 2)) +
    geom_point()

ggsave("persistenceDiagramsH2_nRep2.pdf")
