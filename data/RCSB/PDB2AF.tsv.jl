#!/usr/bin/env julia
using DataFrames
using GZip, JSON
ROOT = readchomp(`git root`)

WORK = "../alphafold/dl/RCSB"

fnames = vcat(readdir.(readdir("$WORK/PH"; join=true); join=true)...)
fnames = fnames[endswith.(fnames, ".json.gz")]
basenames = basename.(fnames)
accs = [split(f, '-')[end][1:end-length(".json.gz")] for f in basenames]
PDBs = [split(f, '_')[begin] for f in basenames] .|> uppercase

df = DataFrame(path_PDB=fnames, PDB=PDBs, accession=accs)

@isdefined(acc2path) || include("$ROOT/data/alphafold/acc2path.jl")
df = innerjoin(df, acc2path; on=:accession)
unique!(df)

CSV.write("PDB2AF.tsv.gz", df; delim='\t', compress=true)

# read_n(path::String) = begin
#     GZip.open(path) do io
#         JSON.parse(io)["n"]
#     end
# end
bts = UInt8[]
"""
Fast version of reading entry "n" from a json, given that it is the first entry.
"""
function readn(f::String)::Int
    GZip.open(f) do io
        # 12 gives e.g. "{\"n\":357,\"y\""
        readbytes!(io, bts, 12)
    end
    s = String(bts)
    @assert s[1:5] == "{\"n\":"
    parse(Int, split(s[6:end], ',')[1])
end
read_pos1_n(path::String) = begin
    GZip.open(path) do io
        d = JSON.parse(io)
        d["pos"] == 1 ? d["n"] : 0
    end
end


@time df.n_PDB = read_pos1_n.(df.path_PDB)
println(nrow(df))
df = df[df.n_PDB .!= 0, :]
println(nrow(df))
@time df.n = readn.(joinpath.("../alphafold/", df.path))
nSameN = sum(df.n .== df.n_PDB)
println(nSameN / nrow(df))
df = df[df.n .== df.n_PDB, :]
df.PDB |> unique |> length |> println
df.accession |> unique |> length |> println

CSV.write("PDB2AF-pos1SameN.tsv.gz", df; delim='\t', compress=true)

for row in eachrow(df)
    outdir = "$WORK/PHcmp/" * row.accession[1:2]
    PDB_chain_model = split(basename(row.path_PDB), '-')[1]
    mkpath(outdir)
    cp(joinpath("../alphafold", row.path), "$outdir/$(row.accession)-AF.json.gz"; force=true)
    cp(row.path_PDB, "$outdir/$(row.accession)-PDB_$PDB_chain_model.json.gz")
end


