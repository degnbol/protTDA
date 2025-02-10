#!/usr/bin/env Rscript
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
    data.table,
    ggplot2,
    cowplot,
    ggh4x,
    svglite,
    dtw,
    seqinr, # read.fasta
    rjson
)

df = fread("./russel1998_table1.tsv", skip=1)
pdbs = df$`PDB code`
chains = list()
for(pdb in strsplit(pdbs, '-')) {
    chains[[pdb[1]]] = pdb[2]
}

msa = read.fasta("msa.fa")

cents = list()
aas = list()
for(filename in list.files("PH")) {
    name = strsplit(filename, '-')[[1]][1]
    pdb = strsplit(name, '_')[[1]]
    chain = chains[[pdb[1]]]
    if(!is.null(chain) && (is.na(chain) || (chain == pdb[2]))) {
        PH = fromJSON(file=paste("PH", filename, sep='/'))
        cents[[pdb[1]]] = PH$cent2
        aas[[pdb[1]]] = PH$aa
    }
}

# a = sample(length(cents), 1)
# b = sample(length(cents), 1)
# a = 4
# b = 10
a = 9
b = 8
name.a = names(cents)[a]
name.b = names(cents)[b]
cent.a = cents[[name.a]]
cent.b = cents[[name.b]]
msa.a = msa[[name.a]]
msa.b = msa[[name.b]]
idx = !((msa.a == '-') & (msa.b == '-'))
msa.a = msa.a[idx]
msa.b = msa.b[idx]
mean(msa.a == '-')
mean(msa.b == '-')

# it was confirmed that the first non-gap letter in msas are the first letter of the unaligned sequence.
aa.a = aas[a]
aa.b = aas[b]

get_aligned = function(values, isgap) {
    out = rep(NA, length(isgap))
    i.val = 0
    for(i.gap in 1:length(isgap)) {
        if(!isgap[i.gap]) {
            i.val=i.val+1
            val = values[i.val]
            if(is.na(val)) {val=0}
            out[i.gap] = val
        }
    }
    out
}

df.ab = data.table(
    msa.a=msa.a,
    msa.b=msa.b,
    msa.cent.a=get_aligned(cent.a, msa.a == '-'),
    msa.cent.b=get_aligned(cent.b, msa.b == '-')
)
df.ab$location = 1:nrow(df.ab)

df.aligned = melt(df.ab, "location", c("msa.cent.a", "msa.cent.b"), variable.name="Protein", value.name="TIF2")
df.unaligned = rbind(
    data.table(location=1:length(cent.a), TIF2=cent.a, Protein=name.a),
    data.table(location=1:length(cent.b), TIF2=cent.b, Protein=name.b)
)
df.aligned$aligned = "Aligned"
df.unaligned$aligned = "Unaligned"
df.aligned[Protein=="msa.cent.a", Protein:=name.a]
df.aligned[Protein=="msa.cent.b", Protein:=name.b]

dtw.alignment = dtw(cent.a, cent.b, keep=T)
# dtw.alignment = dtw(cent.a, cent.b, keep=T, step.pattern=symmetric1)
# dtw.alignment = dtw(cent.a, cent.b, keep=T, step.pattern=symmetricP2)
dtw.alignment.Ib = dtw(cent.a, cent.b, keep=T, step.pattern=typeIb)
dtw.a = data.table(Protein=name.a, TIF2=cent.a[dtw.alignment$index1])
dtw.b = data.table(Protein=name.b, TIF2=cent.b[dtw.alignment$index2])
dtw.Ib.a = data.table(Protein=name.a, TIF2=cent.a[dtw.alignment.Ib$index1])
dtw.Ib.b = data.table(Protein=name.b, TIF2=cent.b[dtw.alignment.Ib$index2])
dtw.a$location = 1:nrow(dtw.a)
dtw.b$location = 1:nrow(dtw.b)
dtw.Ib.a$location = 1:nrow(dtw.Ib.a)
dtw.Ib.b$location = 1:nrow(dtw.Ib.b)
df.dtw = rbind(dtw.a, dtw.b)
df.dtw.Ib = rbind(dtw.Ib.a, dtw.Ib.b)
df.dtw$aligned = "DTW default"
df.dtw.Ib$aligned = "DTW type Ib"
df.gg = rbind(df.unaligned, df.aligned, df.dtw, df.dtw.Ib)
df.gg[, aligned:=factor(aligned, levels=c("Unaligned", "Aligned", "DTW default", "DTW type Ib"))]
df.gg[,Protein:=toupper(Protein)]

ggplot(df.gg, aes(x=location, ymax=TIF2, color=Protein, fill=Protein)) +
    facet_grid2(rows=vars(aligned), scales="free_x", independent="x") +
    geom_ribbon(ymin=0, alpha=0.25) +
    scale_x_continuous(expand=c(0,0)) +
    scale_y_continuous(expand=c(0,0), name="TIF dim 2") +
    scale_color_manual(values=c("maroon", "navy")) +
    scale_fill_manual(values=c("maroon", "navy")) +
    theme_bw()

ggsave("DTW_example.pdf", width=150, height=110, units="mm")

pdf("DTW.pdf", width=6, height=6)
plot(dtw.alignment.Ib, type="threeway", main="Dynamic Time Warping function")
dev.off()

