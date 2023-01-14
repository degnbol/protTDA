#!/usr/bin/env julia
using Distributed

@everywhere begin
using Pkg; Pkg.activate(@__DIR__)
Pkg.instantiate(); Pkg.precompile()

using GZip, CrystalInfoFramework
using CSV, DataFrames
using ThreadPools

WORK = "../alphafold/dl/RCSB"


nUniq(x) = unique(x) |> length

"""
Extract number of residues from CIF per chain and model.
"""
function readCIF(path::String)
    lines = if endswith(path, ".gz")
        GZip.open(path) do io readlines(io) end
    else
        open(path) do io readlines(io) end
    end
    nc = Cif(join(lines, '\n'))     
    # there should only be a pair PDB id => Cif
    cif = only(nc).second
    title = only(cif["_entry.id"])
    
    df = DataFrame(
         :chain => cif["_atom_site.label_asym_id"],
         :model => cif["_atom_site.pdbx_PDB_model_num"],
         :resi => cif["_atom_site.label_seq_id"]
        )
    
    df = df[df.resi .!= nothing, :]
    
    df = combine(groupby(df, [:chain, :model]), :resi => nUniq => :nRes)
    df = combine(groupby(df, :nRes), nrow)
    df[!, :PDB] .= title
    df
end

end

fnames = vcat(readdir.(readdir("$WORK/mmCIF"; join=true); join=true)...);

# compile
@time df = @distributed vcat for f in fnames[1:48]
    readCIF(f)
end
@time df = @distributed vcat for f in fnames
    println(f)
    readCIF(f)
end

CSV.write("$WORK/nRes.tsv.gz", df; delim='\t', compress=true)

