#!/usr/bin/env julia
using GZip
using JSON3
using CSV, DataFrames
using Statistics
ROOT = `git root` |> readchomp
include("$ROOT/src/util/glob.jl")
PH = "$ROOT/data/alphafold/PH"

df_acc = CSV.read("thermozymes-acc-unjag.tsv.gz", DataFrame)
df_tax = CSV.read("taxons.tsv", DataFrame)

fnames = String[]
fname_taxs = Int[]
for tax in df_tax.taxon
    tax_fnames = glob("$PH/$(string(tax)[1:3])/$tax-*/AF-*")
    append!(fnames, tax_fnames)
    append!(fname_taxs, fill(tax, length(tax_fnames)))
end

fname_accs = [split(b, '-')[2] for b in basename.(fnames)]
df_prot = DataFrame(acc=fname_accs, taxon=fname_taxs, path=fnames)
leftjoin!(df_prot, unique(df_tax[!, [:taxon, :thermophile]]); on=:taxon)
df_ol = innerjoin(df_prot, df_acc; on=:acc)

# only keep entries for a given EC where there is both thermophile and 
# mesophile examples
df_EC_n = combine(groupby(unique(df_ol[!, [:EC, :thermophile]]), :EC), nrow => :n)
df_ol = innerjoin(df_ol, df_EC_n[df_EC_n.n .> 1, [:EC]]; on=:EC)

readPH(fname) = GZip.open(fname) do io
    d = JSON3.read(io, Dict)
    births1, deaths1 = d["bars1"]
    births2, deaths2 = d["bars2"]
    pers1 = deaths1 .- births1
    pers2 = deaths2 .- births2
    sRep1 = length.(d["reps1"])
    sRep2 = length.(d["reps2"])
    DataFrame(path=fname, birth2=births2, death2=deaths2, pers2=pers2, nRep2=sRep2)
end

df_summ = vcat(readPH.(df_ol.path)...)
df_summ = innerjoin(df_summ, df_ol; on=:path)

CSV.write("thermozymes-acc-unjag-summ.tsv.gz", df_summ; delim='\t', compress=true)
