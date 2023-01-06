#!/usr/bin/env julia
using DataFrames, CSVFiles
using GZip
ROOT = readchomp(`git root`)

# '\\' is a hack. I want to simply disable quotechar but that isn't possible so 
# I set it to a char that isn't present in the file.
# I want to disable it since there are quotes in the files and they shouldn't 
# be used in any special way.
df = load(File(format"TSV", "peptidases-TEMPURA.tsv.gz"); quotechar='\\') |> DataFrame

# generate acc2path::DataFrame with columns :accession, :path
include("$ROOT/data/alphafold/acc2path.jl")

leftjoin!(df, acc2path, on=:accession)
unique!(df)

save(File(format"TSV", "peptidases-TEMPURA-AF.tsv.gz"), df; quotechar=nothing)

# get just the unique mappings from accessions to paths for when an optimal 
# temp is known
df_acc2path = df[df.Topt_ave .!== missing, [:accession, :path]]
unique!(df_acc2path)
dropmissing!(df_acc2path)

# get copies of the PH for the accessions of interest.
mkpath("$ROOT/data/alphafold/dl/MEROPS/PH")
for row in eachrow(df_acc2path)
    cp("$ROOT/data/alphafold/"*row.path, "$ROOT/data/alphafold/dl/MEROPS/PH/$(row.accession).json.gz")
end

