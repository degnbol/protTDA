#!/usr/bin/env julia
using DataFrames
ROOT = readchomp(`git root`)

include("$ROOT/data/alphafold/acc2path_anno.jl")
df = annoAF("peptidases-TEMPURA.tsv.gz")

# get just the unique mappings from accessions to paths for when an optimal 
# temp is known
df_acc2path = df[df.Topt_ave .!== missing, [:accession, :path]]
unique!(df_acc2path)
dropmissing!(df_acc2path)

# get copies of the PH for the accessions of interest.
mkpath("$ROOT/data/MEROPS/PH")
for row in eachrow(df_acc2path)
    cp("$ROOT/data/alphafold/"*row.path, "$ROOT/data/MEROPS/PH/$(row.accession).json.gz")
end

