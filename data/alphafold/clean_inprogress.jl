#!/usr/bin/env julia

d2s = [d2 for d1 in readdir("PH"; join=true) for d2 in readdir(d1; join=true)]
println(length(d2s), " dirs")
isf = isfile.(joinpath.(d2s, ".inprogress"))
println(sum(isf), " dirs with .inprogress")
inp = d2s[isf]
rm.(inp .* "/louvain.json.gz")
rm.(inp .* "/.inprogress")

