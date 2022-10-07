#!/usr/bin/env julia
using PyCall
@pyinclude "fetch.py"
ROOT = readchomp(`git root`)
# include("$ROOT/tools/Eirene.jl/src/Eirene.jl")
include(expanduser("~/Eirene.jl/src/Eirene.jl"))
using JSON
using GZip
using Distances

global xyz, name, bs, rs
for (name, xyz) in py"gen_xyzs"(max_results=1)
    # discard "AF-" ... "-model_v3"
    name = name[4:end-9]
    println(name, " ", size(xyz, 1))
    # bs, rs = Eirene.eirene(xyz, 2; minrad=0.)
    bs = Eirene.eirene(pairwise(Euclidean(), xyz; dims=1), maxdim=2)
    break
    d = Dict("H1" => Dict("barcode"=>bs[1], "representatives"=>rs[1]),
             "H2" => Dict("barcode"=>bs[2], "representatives"=>rs[2]))
    outdir = name[1:2]*"/"*name[3:4]
    mkpath(outdir)
    GZip.open(outdir*"/"*name*".json.gz", "w") do io JSON.print(io, d) end
end

