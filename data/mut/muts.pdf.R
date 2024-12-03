#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(ggplot2))

dt = fread("./mutations.csv.gz", select=c(
    "Type",
    "Structural prediction",
    "confidence",
    "Centrality degree 1",
    "Centrality degree 2"
))
dt = dt[confidence == "high"]
dt[,confidence:=NULL]
setnames(dt, "Type", "Disease")
setnames(dt, "Structural prediction", "Structural")
setnames(dt, "Centrality degree 1", "1D cycles")
setnames(dt, "Centrality degree 2", "2D cycles")

dtm = melt(dt, c("Disease", "Structural"), variable.name="Dimension", value.name="TIF")
dtm[Disease=="Disease", Disease:="Damaging"]
dtm[Structural=="Disease", Structural:="Damaging"]
dtm[, Disease:=factor(Disease, levels=c("Neutral", "Damaging"))]
dtm[, Structural:=factor(Structural, levels=c("Neutral", "Damaging"))]

ggplot(dtm, aes(Structural, TIF, color=Disease, fill=Structural)) +
    facet_grid(cols=vars(Dimension)) +
    geom_boxplot(notch=TRUE, linewidth=0.9) +
    theme_bw() +
    scale_fill_manual(values=c("white", "#e68e87")) +
    scale_color_manual(values=c("#2f2f2f", "#c20d00")) +
    scale_y_continuous(expand=expansion(mult=c(0,0))) +
    theme(
        panel.grid.major.x=element_blank(),
        panel.grid.minor.x=element_blank(),
        axis.ticks.x=element_blank()
    )

ggsave("muts.pdf", width=5.55, height=4.64)

