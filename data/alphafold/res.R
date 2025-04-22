#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(data.table))
library(ggplot2)

dt = fread("res.tsv")
dt[,H:=NULL]
# peak strongly correlated with RSS (corr=.98 using mlr).
# Use RSS which is measured for all methods.
dt[,peak:=NULL]
# RSS is said to be in kbytes in unix time man page but it doesn't make sense 
# see the numbers are too big. I assume it is in bytes.
dt[,RSS:=RSS / 1e9]

# giotto was calculated with 5 and 10 cores.
# For 1 core comparison we linearly extrapolate.
# f(x) = ax+b. f(5)=5a+b, f(10)=10a+b. f(1)=a+b=?
# b = f(5)-5a. f(10)=10a+f(5)-5a => a=(f(10)-f(5))/5
# f(1)=a+b=(f(10)-f(5))/5 + f(5)-5((f(10)-f(5))/5) = (1/5-1) f(10) + (2-1/5) f(5)
f1 = function(f5, f10) { return((1/5-1) * f10 + (2-1/5) * f5) }
dt = rbind(dt, data.table(method="giotto", rep="no",
           time=f1(dt[method=="giotto (5 CPUs)", time], dt[method=="giotto (10 CPUs)", time]),
           RSS =f1(dt[method=="giotto (5 CPUs)", RSS],  dt[method=="giotto (10 CPUs)", RSS])
))
dt = dt[! method %in% c("giotto (5 CPUs)", "giotto (10 CPUs)")]

# renames for plotting
setnames(dt, "time", "time [s]")
setnames(dt, "RSS", "memory [GB]")
setnames(dt, "rep", "Calc reps")
dtm = melt(dt, measure.vars=c("time [s]", "memory [GB]"), variable.name="variable", value.name="value")


ggplot(dtm, aes(x=method, y=value, fill=`Calc reps`)) +
    facet_grid(rows="variable", scales="free_y", switch="y") +
    geom_col(position="dodge") +
    geom_text(data=dtm[method=="ripserer.jl alpha"], aes(label=round(value, 3)), vjust=0, size=2.5) +
    xlab("method") +
    scale_y_continuous(expand=expansion(mult=c(0,.05))) +
    scale_fill_manual(name="Calculates\nrepresentatives", values=c("gray", "green")) +
    theme_classic() +
    theme(axis.title.y=element_blank(),
          axis.text.x=element_text(angle=45, hjust=1),
          panel.grid.minor.x=element_blank(),
          panel.grid.major.x=element_blank(),
          panel.border=element_blank(),
          strip.placement="outside",
          strip.background=element_blank()
    )

ggsave("AF_bench.pdf", width=4, height=6)


df = fread("oracle_metrics.tsv")
df[, timestamp:=as.POSIXct(timestamp, tz="GMT")]
# MB/s
df[, diskReadMB:=diskReadBytes/1e6]
df[, diskWriteMB:=diskWriteBytes/1e6]

df.melt = melt(df, "timestamp", c("memoryPercent", "cpuPercent", "diskReadMB", "diskWriteMB"))

MBs = c("diskReadMB", "diskWriteMB")
# scale to use dual axis
scl = ceiling(max(df.melt[variable%in%MBs, value])) / 100
df.melt[variable%in%MBs, value:=value/scl]

df.melt[variable=="memoryPercent", variable:="Memory"]
df.melt[variable=="cpuPercent", variable:="CPU"]
df.melt[variable=="diskReadMB", variable:="Read"]
df.melt[variable=="diskWriteMB", variable:="Write"]

ggplot(df.melt, aes(x=timestamp, y=value, color=variable, linetype=variable)) +
    geom_line() +
    scale_y_continuous(name="%", limits=c(0,100), expand=c(0,0),
                       sec.axis=sec_axis(~.*scl, name="MB/s")) +
    xlab("Timestamp") +
    scale_linetype_manual(values=c("solid", "solid", "dashed", "dashed"), guide="none") +
    scale_color_manual(name="Measurement", values=c("maroon", "blue", "black", "darkgray")) +
    theme_classic()

ggsave("AF_PH_run.pdf", width=6, height=2)

dtt = dt[`Calc reps`=="yes" & method%in%c("eirene.jl", "ripserer.jl alpha"), c("method", "time [s]")]
dtt[, `time [days/160CPUs]` := `time [s]` * 214000000 / 60 / 60 / 24 / 160]
dtt[, `time [s]`:= NULL]
dtt[, method:=paste(method, "est")]

duration = df[, max(timestamp) - min(timestamp)]
duration = ceiling(as.numeric(duration))

dtt = rbind(dtt, data.table(method="actual", `time [days/160CPUs]`=duration))
eirene = "eirene.jl est"
ripserer = "ripserer.jl alpha est"
actual = "actual"
dtt[, method:=factor(method, levels=c(eirene, ripserer, actual))]
dtt[method==eirene, label:="2.5 years"]
dtt[method==ripserer, label:="1 month\n18 days"]
dtt[method==actual, label:="< 3 days"]

ggplot(dtt, aes(x=method, y=`time [days/160CPUs]`, label=label)) +
    geom_col() +
    geom_text(vjust=-.2, size=3) +
    scale_y_continuous(expand=expansion(mult=c(0,.05))) +
    theme_bw() +
    theme(axis.text.x=element_text(angle=45, hjust=1),
          panel.border=element_blank(),
          panel.grid=element_blank()
    )

ggsave("AF_actual.pdf", width=2, height=6)

