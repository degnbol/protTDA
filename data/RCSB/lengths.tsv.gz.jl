#!/usr/bin/env julia
using Distributed

@everywhere begin
using Pkg; Pkg.activate(@__DIR__)
Pkg.instantiate(); Pkg.precompile()

using GZip, CrystalInfoFramework
using CSV, DataFrames
using ThreadPools

nUniq(x) = unique(x) |> length

"""
Extract number of residues from CIF per chain and model.
"""
function readCIF(path::String)
    lines = try
        if endswith(path, ".gz")
            GZip.open(path) do io readlines(io) end
        else
            open(path) do io readlines(io) end
        end
    catch e
        println("Error for file $path: ", e)
        return DataFrame(:nRes=>Int[], :nrow=>Int[], :PDB=>String[])
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

fnames = vcat(readdir.(readdir("mmCIF"; join=true); join=true)...);

@time df = reduce(vcat, pmap(readCIF, [fnames[1]; "TEST_NOT_A_FILENAME"; fnames[2]]))
# compile and estimate time to finish
@time df = reduce(vcat, pmap(readCIF, fnames[1:150]))
@time df = reduce(vcat, pmap(readCIF, fnames))

CSV.write("nRes.tsv.gz", df; delim='\t', compress=true)

