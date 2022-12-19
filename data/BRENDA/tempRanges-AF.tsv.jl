#!/usr/bin/env julia
using DataFrames, CSV
ROOT = run(`git root`)
# generate acc2path::DataFrame with columns :accession, :path
include("$ROOT/data/alphafold/acc2path.jl")

df = CSV.read("tempRanges.tsv", DataFrame)
leftjoin!(df, acc2path, on=:accession)

CSV.write("tempRanges-AF.tsv", df; delim='\t')

