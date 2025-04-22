#!/usr/bin/env Rscript
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
    data.table,
    ggplot2,
    cowplot,
    ggh4x,
    svglite,
    ggridges # geom_density_ridges
)

col_meso   = "#267692"
col_thermo = "#E23935"

suppl = "../../Results"
df = fread(paste0(suppl, "/thermophiles/SEQ.csv"))
df.AA = fread("./AA_volumes.tsv")

setnames(df, "Seq", "AA")
df = df[df.AA,on="AA"]

df[thermo==0, phile:="Mesophile"]
df[thermo==1, phile:="Thermophile"]

# simple correlations
cor.test(df[thermo==0,Cent2], df[thermo==0,Volume])
cor.test(df[thermo==1,Cent2], df[thermo==1,Volume])
# two trend lines for the plot
model.meso = lm(Cent2 ~ Volume, data=df[thermo==0])
model.thermo = lm(Cent2 ~ Volume, data=df[thermo==1])
summary(model.meso)
summary(model.thermo)
confint(model.meso)["Volume",]
confint(model.thermo)["Volume",]
summary(model.meso)$r.squared
summary(model.thermo)$r.squared
# We want to test whether there are compensating effects from AA volume distributions for void sizes in meso vs thermo.
median(df[thermo==0,Volume])
median(df[thermo==1,Volume])
mean(df[thermo==0,Volume])
mean(df[thermo==1,Volume])
wilcox.test(df[thermo==0,Volume], df[thermo==1,Volume])

p1 = ggplot() +
    geom_density_ridges(data=df[thermo==0], mapping=aes(y=Volume, group=Volume, x=Cent2), panel_scaling=FALSE, scale=-0.5, alpha=0.2, color=col_meso, fill=col_meso) +
    geom_density_ridges(data=df[thermo==1], mapping=aes(y=Volume, group=Volume, x=Cent2), panel_scaling=FALSE, scale=+0.5, alpha=0.2, color=col_thermo, fill=col_thermo) +
    scale_y_continuous(expand=c(0,0), limits=c(55,235), name="AA volume") +
    scale_x_continuous(expand=c(0,0), limits=c(0,1), name="TIF") +
    theme_classic() +
    coord_flip()
p1

p2 = ggplot() +
    geom_smooth(data=df, mapping=aes(x=Volume, y=Cent2, color=phile), method="lm", se=TRUE) +
    scale_color_manual(values=c(col_meso, col_thermo), guide="none") +
    scale_x_continuous(expand=c(0,0), limits=c(55,235), name="AA volume") +
    scale_y_continuous(expand=c(0,0), limits=c(0,1), name="TIF") +
    theme_classic()
p2

# ggsave("AA_volume_violins.pdf", p1, width=10, height=3)
# ggsave("AA_volume_lm.pdf", p2, width=10, height=3)

# write figure data for publication
df.pub = df[, .(thermophile=thermo, accession=acc, AA, AA_volume=Volume, TIF2=Cent2)]
fwrite(df.pub, "../../Results/figures/Figure4C-S16.tsv.gz")
