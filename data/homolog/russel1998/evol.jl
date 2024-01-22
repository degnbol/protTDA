#!/usr/bin/env julia
# cmp regular seq alignment to cool new topology based ones.
# seq align across genetic distance and compare topology similarity vs genetic distance.
using CSV, DataFrames
using DelimitedFiles
using Chain
using GZip, JSON
using Glob
using EzXML: parsexml
include("blastcommandline.jl")
using FastaIO
using StatsBase
using LinearAlgebra
using PlotlyJS
using RCall

df = CSV.read("./russel1998_table1.tsv", DataFrame; delim='\t', header=2)

rename!(df, "PDB code"=>"pdb", "Fold or protein name"=>"fold")

df[!, "chain"] .= @chain df[!, "pdb"] split.('-') get.(2, "a")
df[!, "pdb"]   .= @chain df[!, "pdb"] split.('-') get.(1, nothing)
# there are two rows with chain ab. There are no PHs generated for the first 
# file and the second PDB has an only 8 aa long chain A, so we use B.
df[df.pdb .== "1lmw", "chain"] .= "b"

df[!, "aa"] .= ""

for fname in readdir("PH/")
    # lowercase to match case-insensitive
    pdb, chain, = split(lowercase(fname), '_')
    PH = GZip.open("PH/$fname") do io
        JSON.parse(io)
    end
    idx = (df.pdb .== pdb) .& (df.chain .== chain)
    df[idx, "aa"] .= PH["aa"]
end

df = df[(df.aa .!= "") .& (length.(df.aa) .> 20), :]

# there is only 1 relevant chain for each pdb
dfChainPerPdb = @chain df groupby([:pdb]) combine(:chain => x -> length(unique(x)))
@assert all(dfChainPerPdb.chain_function .== 1)

if isfile("blast.tsv.gz")
    df2 = CSV.read("blast.tsv.gz", DataFrame; delim='\t')
    df2.qrange = [range(parse.(Int, split(r, ':'))...) for r in df2.qrange]
    df2.hrange = [range(parse.(Int, split(r, ':'))...) for r in df2.hrange]
    N = nrow(df2)
else
    df2 = unique(df[!, [:pdb, :fold, :chain, :aa]])
    N = nrow(df2)
    aligns = [blastp(df2.aa[i], df2[Not(i), :aa]) for i in 1:N]
    aligns = only.(aligns)
    aligns = DataFrame(aligns)
    aligns.hit .= parse.(Int, aligns.hit)
    df2 = hcat(df2, aligns)
    # since we remove the entry itself we add 1 to index if hit is after row i.
    df2.hit[df2.hit .≥ 1:N] .+= 1
    CSV.write("blast.tsv.gz", df2; delim='\t', compress=true)
end

# read cents
cent1 = Vector{Float64}[]
cent2 = Vector{Float64}[]
for row in eachrow(df2)
    fname = glob("PH/$(row.pdb)_$(uppercase(row.chain))_1-*.json.gz") |> only
    PH = GZip.open(fname) do io
        JSON.parse(io)
    end
    # cent vectors may be shorter than #points where zeros should be added at end
    nAA = length(row.aa)
    nCent1 = length(PH["cent1"])
    nCent2 = length(PH["cent2"])
    @assert nCent1 .≤ nAA
    @assert nCent2 .≤ nAA
    push!(cent1, zeros(nAA))
    push!(cent2, zeros(nAA))
    cent1[end][1:nCent1] .= PH["cent1"]
    cent2[end][1:nCent2] .= PH["cent2"]
end


df2[!, "cent1_cor"] .= NaN;
df2[!, "cent2_cor"] .= NaN;
for (i, row) in enumerate(eachrow(df2))
    @assert replace(row.hseq, '-'=>"") == df2[row.hit, :aa][row.hrange]
    qvalid = collect(row.qseq) .!= '-'
    hvalid = collect(row.hseq) .!= '-'
    valid = qvalid .& hvalid
    qcent1 = cent1[i][row.qrange][valid[qvalid]]
    qcent2 = cent2[i][row.qrange][valid[qvalid]]
    hcent1 = cent1[row.hit][row.hrange][valid[hvalid]]
    hcent2 = cent2[row.hit][row.hrange][valid[hvalid]]
    row.cent1_cor = cor(qcent1, hcent1)
    row.cent2_cor = cor(qcent2, hcent2)
end


# last sentence of first link references the paper below and says:
# "The bit-score provides a better rule-of-thumb for inferring homology"
# about looking at e-value (expect) vs bitscore. So we are happy using bitscore 
# as a measure of sequency similarity as the established way of inferring 
# homology.
# https://ravilabio.info/notes/bioinformatics/e-value-bitscore.html
# https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3820096/
# https://doi.org/10.1002%2F0471250953.bi0301s42
cor(df2.bitscore, df2.cent1_cor)
cor(df2.bitscore, df2.cent2_cor)
cor(log.(df2.bitscore), df2.cent2_cor)
# high correlation between bitscore (proxy for evol dist) and cents.
scatter(x=df2.bitscore, y=df2.cent1_cor, mode="markers") |> plot
scatter(x=df2.bitscore, y=df2.cent2_cor, mode="markers") |> plot
scatter(x=log.(df2.bitscore), y=df2.cent2_cor, mode="markers") |> plot

if !isfile("msa.fa")
    open("to_msa.fa", "w") do io
        for row in eachrow(df2)
            write(io, ">$(row.pdb)\n$(row.aa)\n")
        end
    end
    run(`muscle -in to_msa.fa -out msa.fa`)
end
msa = Dict{String,String}()
FastaReader("msa.fa") do fr
    for (desc, seq) in fr msa[desc] = seq end
end
msas = [collect(msa[pdb]) for pdb in df2.pdb]

identFrac = zeros(length(msas), length(msas));
cent1_cors = zeros(length(msas), length(msas));
cent2_cors = zeros(length(msas), length(msas));
for i in 1:N
    for j in 1:N
        mi = msas[i]
        mj = msas[j]
        ungapi = mi .!= '-'
        ungapj = mj .!= '-'
        ungap = ungapi .& ungapj
        ident = mi .== mj .!= '-'
        outof = min(sum(ungapi), sum(ungapj))
        identFrac[i,j] = sum(ident) / outof
        c1i = cent1[i][ungap[ungapi]]
        c1j = cent1[j][ungap[ungapj]]
        c2i = cent2[i][ungap[ungapi]]
        c2j = cent2[j][ungap[ungapj]]
        cent1_cors[i,j] = cor(c1i, c1j)
        cent2_cors[i,j] = cor(c2i, c2j)
    end
end


if isfile("RMSDs.ssv")
    rmsds = readdlm("RMSDs.ssv", ' ')
else
    rmsds = zeros(N, N);
    for i in 1:N
        print("$i/$N\r")
        for j in i+1:N
            pdbi = df2.pdb[i]
            pdbj = df2.pdb[j]
            chaini = df2.chain[i] |> uppercase
            chainj = df2.chain[j] |> uppercase
            rmsds[i,j] = parse(Float64, readchomp(`./RMSD.sh $pdbi $chaini $pdbj $chainj`))
        end
    end
    writedlm("RMSDs.ssv", rmsds, ' ')
end
for i in 1:N for j in i+1:N
    rmsds[j,i] = rmsds[i,j]
end end
df2[!, "RMSD"] .= [rmsds[i,j] for (i,j) in zip(1:N, df2.hit)]

# made in fda.py
fisherrao = readdlm("fisherrao.ssv", ' ')
df2[!, "fisherrao"] .= [fisherrao[i,j] for (i,j) in zip(1:N, df2.hit)]


R"install.packages('elasdics')"

elastic_dists = Float64[]
for (i, hit) in enumerate(df2.hit)
    a = cent2[i]
    b = cent2[hit]
    @rput a
    @rput b
    R"""
    library("elasdics")
    A = data.frame(t=0:(length(a)-1) / (length(a)-1), y=a)
    B = data.frame(t=0:(length(b)-1) / (length(b)-1), y=b)
    elastic_dist = align_curves(A, B)$elastic_dist
    """
    push!(elastic_dists, @rget(elastic_dist))
end
df2[!, "elastic_dist"] .= elastic_dists



utri = triu!(trues(N, N), 1)
cor(identFrac[utri], cent1_cors[utri])
cor(identFrac[utri], cent2_cors[utri])
scatter(x=identFrac[utri], y=cent1_cors[utri], mode="markers") |> plot
scatter(x=identFrac[utri], y=cent2_cors[utri], mode="markers") |> plot

cor(fisherrao[utri], identFrac[utri])
cor(fisherrao[utri], cent1_cors[utri])
cor(fisherrao[utri], cent2_cors[utri])
scatter(x=identFrac[utri], y=fisherrao[utri], mode="markers") |> plot


cor(rmsds[utri], identFrac[utri])
cor(rmsds[utri], cent1_cors[utri])
cor(rmsds[utri], cent2_cors[utri])
cor(rmsds[utri], fisherrao[utri])
scatter(x=rmsds[utri], y=identFrac[utri], mode="markers") |> plot
scatter(x=rmsds[utri], y=cent2_cors[utri], mode="markers") |> plot

cor(df2.bitscore, df2.RMSD)
cor(df2.cent1_cor, df2.RMSD)
cor(df2.cent2_cor, df2.RMSD)
scatter(x=df2.bitscore, y=df2.RMSD, mode="markers") |> plot

cor(df2.elastic_dist, df2.bitscore)
cor(df2.elastic_dist, df2.RMSD)
# the two measures of curve align dist are not even that correlated
cor(df2.elastic_dist, df2.fisherrao)
cor(df2.elastic_dist, df2.cent1_cor)
cor(df2.elastic_dist, df2.cent2_cor)




# An example to look at the potential for aligning using cent or other topol

i = (df2.pdb .== df2.pdb[end-3]) |> findall |> only
a = cent2[i]
b = cent2[df2.hit[end-3]]

row = df2[i, :]
qvalid = collect(row.qseq) .!= '-'
hvalid = collect(row.hseq) .!= '-'
valid = qvalid .& hvalid
qcent1 = cent1[i][row.qrange][valid[qvalid]]
qcent2 = cent2[i][row.qrange][valid[qvalid]]
hcent1 = cent1[row.hit][row.hrange][valid[hvalid]]
hcent2 = cent2[row.hit][row.hrange][valid[hvalid]]

plot([
scatter(y=a),
scatter(y=b)
])

plot([
scatter(y=qcent2),
scatter(y=hcent2)
])

# so the curves look super similar after alignment, could we align them without 
# seq?


