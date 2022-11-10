#!/usr/bin/env julia
using Random
ROOT = readchomp(`git root`)

omes = vcat([readdir(d1) for d1 in readdir("PH"; join=true)]...)
println(length(omes), " proteomes")

omes = omes[.!isfile.(omes .* "/.inprogress")]
println(length(omes), " todo")

shuffle!(omes)

for outdir in omes[1:min(1000,length(todo))]
    touch(outdir*"/.inprogress")
    println(proteome)
    res = run(`$ROOT/src/louvain.py $outdir $outdir/louvain.json`)
    res.exitcode == 0 && rm(outdir*"/.inprogress")
end

