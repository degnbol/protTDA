#!/usr/bin/env julia
using Random
ROOT = readchomp(`git root`)

omes = vcat([readdir(d1; join=true) for d1 in readdir("PH"; join=true)]...)
println(length(omes), " proteomes")

omes = omes[.!isfile.(omes .* "/louvain.json.gz")]
println(length(omes), " todo")

shuffle!(omes)

for outdir in omes[1:min(1000,length(omes))]
    isfile(outdir*"/.inprogress") && continue
    touch(outdir*"/.inprogress")
    println(outdir)
    res = run(`$ROOT/src/louvain.py $outdir/'AF*.json.gz' $outdir/louvain.json.gz`)
    res.exitcode == 0 && rm(outdir*"/.inprogress")
end

