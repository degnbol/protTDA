#!/usr/bin/env Rscript
if (!require("pacman")) install.packages("pacman")
pacman::p_load(data.table, ggplot2, cowplot, ggh4x, svglite, dtw)

a = fread("a.tsv")
b = fread("b.tsv")

alignment = dtw(a, b, keep=T)

plot(alignment, type="threeway")

