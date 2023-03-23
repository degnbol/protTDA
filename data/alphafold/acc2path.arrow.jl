#!/usr/bin/env julia
using Arrow
using DataFrames

d0s = readdir("PH"; join=true)
d0s = d0s[match.(r"^[0-9]", basename.(d0s)) .!= nothing]
d1s = vcat(readdir.(d0s; join=true)...)
@time df = DataFrame(path=vcat(readdir.(d1s; join=true)...))
path2acc(path::String) = split(basename(path), '-')[2]
@time df.acc = path2acc.(df.path)
@time Arrow.write("acc2path.arrow", df)
