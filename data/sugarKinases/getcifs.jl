#!/usr/bin/env julia
using CSV, DataFrames
using Tar: extract
ROOT = readchomp(`git root`)
include("$ROOT/src/util/glob.jl")

dProteome = "$ROOT/data/proteomes" #/proteome-tax_id-391366-0_v3.tar

mkpath("cif")

df = CSV.read("bork1992_table1-unjag-uniprot-path.tsv", DataFrame)

for (phpath, acc) in eachrow(df[!, [:path, :acc]])
    taxv = splitpath(phpath)[end-1]
    println("$taxv $acc")
    fname = "AF-$acc-F1-model_v3.cif.gz"
    isfile("cif/$fname") && continue
    dir = extract(h -> (h.path == fname), "$dProteome/proteome-tax_id-$(taxv)_v3.tar")
    mv("$dir/$fname", "cif/$fname")
    rm(dir)
end

