#!/usr/bin/env julia
using DataFrames
ROOT = readchomp(`git root`)

include("$ROOT/data/alphafold/acc2path_anno.jl")

dfs = Dict{String,DataFrame}()
for filename in readdir()
    if endswith(filename, "-TEMPURA.tsv")
        name = filename[1:end-length(".tsv")]
    elseif endswith(filename, "-TEMPURA.tsv.gz")
        name = filename[1:end-length(".tsv.gz")]
    else
        continue
    end
    dfs[name] = annoAF(filename)
end

for (name, df) in dfs
    println(name)
    
    # get just the unique mappings from accessions to paths for when an optimal 
    # temp is known
    df_acc2path = df[df.Topt_ave .!== missing, [:accession, :path]]
    unique!(df_acc2path)
    dropmissing!(df_acc2path)

    # get copies of the PH for the accessions of interest.
    outdir = "$ROOT/data/interpro/$name-PH"
    mkpath(outdir)
    for row in eachrow(df_acc2path)
        cp("$ROOT/data/alphafold/"*row.path, "$outdir/$(row.accession).json.gz")
    end
end

