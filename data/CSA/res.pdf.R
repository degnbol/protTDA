#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(data.table))
library(ggplot2)
library(gridExtra)

dt = fread("res.tsv")

dt[, GB:=as.integer(sub("MB", "", MB)) / 1000]
dt[, H:=as.character(H)]
dt[H=="2", H:="1&2"]
dt[, time:=as.POSIXct(time, format="%H:%M:%S")]


p.GB = ggplot(dt, aes(x=npoints, color=H)) +
    xlab("points") +
    ylab("memory [GB]") +
    ylim(0, 150) +
    geom_hline(yintercept=125, color="red") +
    geom_point(aes(y=GB))


p.time = ggplot(dt, aes(x=npoints, color=H)) +
    xlab("points") +
    scale_y_datetime(name="time [H:M]", date_labels="%H:%M") +
    geom_point(aes(y=time))

p = grid.arrange(p.GB, p.time, ncol=1)
ggsave("res.pdf", p)


