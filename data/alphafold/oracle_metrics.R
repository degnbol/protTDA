#!/usr/bin/env Rscript
library(data.table)
library(ggplot2)

df = fread("oracle_metrics.tsv")
df[, timestamp:=as.POSIXct(timestamp, tz="GMT")]
# MB/s
df[, diskReadMB:=diskReadBytes/1e6]
df[, diskWriteMB:=diskWriteBytes/1e6]
df[, diskReadBytes:=NULL]
df[, diskWriteBytes:=NULL]

df.melt = melt(df, id.vars="timestamp")

ggplot(df.melt, aes(x=timestamp, y=value, color=variable)) +
    facet_wrap(. ~ variable, scales="free_y") +
    geom_line() +
    expand_limits(y=0)
    

ggsave("oracle_metrics.pdf", width=8, height=7)
