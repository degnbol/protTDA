#!/usr/bin/env Rscript
if (!require("pacman")) install.packages("pacman")
pacman::p_load(data.table, ggplot2, cowplot, ggh4x, svglite)

df = fread("./thermo_all_new.csv.gz", drop=c("V1", "EC"))
df.EC = fread("../../Results/thermophiles/summary.csv")
df = df[df.EC,on="acc"]
setnames(df, "Volume of voids", "volume")
setnames(df, "PH", "persistence")
setnames(df, "thermo", "phile")
setnames(df, "len", "residues")
df = df[!is.na(volume)]
fwrite(df, "./void_volumes.tsv.gz")

df = df[confidence=="high"][persistence>1]

wilcox.test(
    df[phile=="thermo", volume],
    df[phile=="meso", volume]
    ,alternative="l"
)

# look at EC distribution
dfN = df[, .N, by=.(EC, phile)]
dfN = dcast(dfN, EC ~ ..., value.var="N")
dfN[,frac:=thermo/meso]
dfN
# not balanced. We sample equal amonts from each.

n.samples = 1000
df.sampled = df[,.(volume=sample(volume, n.samples, replace=T)), by=.(EC, phile)]

wilcox.test(
    df.sampled[phile=="thermo", volume],
    df.sampled[phile=="meso", volume]
    ,alternative="l"
)

