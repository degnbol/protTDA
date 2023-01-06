#!/usr/bin/env julia
using DataFrames
ROOT = readchomp(`git root`)

include("$ROOT/data/alphafold/acc2path_anno.jl")
df = annoAF("tempRanges.tsv")

# get just the unique mappings from accessions to paths for when an optimal 
# temp is known
df_acc2path = df[df.tempOptimMin .!== missing, [:accession, :path]]
unique!(df_acc2path)
dropmissing!(df_acc2path)

# get copies of the PH for the accessions of interest.
for row in eachrow(df_acc2path)
    cp("$ROOT/data/alphafold/"*row.path, "PH/$(row.accession).json.gz")
end
