#!/usr/bin/env julia
using DataFrames, CSV
ROOT = readchomp(`git root`)
# generate acc2path::DataFrame with columns :accession, :path
include("$ROOT/data/alphafold/acc2path.jl")

df = CSV.read("tempRanges.tsv", DataFrame)
leftjoin!(df, acc2path, on=:accession)
unique!(df)

CSV.write("tempRanges-AF.tsv", df; delim='\t')

# get just the unique mappings from accessions to paths for when an optimal 
# temp is known
df_acc2path = df[df.tempOptimMin .!== missing, [:accession, :path]]
unique!(df_acc2path)
dropmissing!(df_acc2path)

# get copies of the PH for the accessions of interest.
for row in eachrow(df_acc2path)
    cp("$ROOT/data/alphafold/"*row.path, "PH/$(row.accession).json.gz")
end
