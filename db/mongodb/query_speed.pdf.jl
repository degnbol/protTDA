#!/usr/bin/env julia
using Gadfly
using DataFrames

df = DataFrame(nPersist=Int[],
               N=Int[],
               duration=Float64[],
               time=Int[],
               fsUsedSize=Int[],
               objects=Union{Missing,Int}[],
               avgObjSize=Union{Missing,Float64}[],
               dataSize=Union{Missing,Int}[],
               storageSize=Union{Missing,Int}[],
               indexSize=Union{Missing,Int}[],
               totalSize=Union{Missing,Int}[],
               lang=String[],)

Ts = df |> eachcol .|> eltype .|> nonmissingtype

open("query_speed.jl.out") do io
    for line in readlines(io)
        row = split(line, ' ')[[1, 3, 5, 7, 9]]
        row = [parse(T,v) for (v,T) in zip(row, Ts)]
        row = [row; [missing for _ in 1:6]; "jl"]
        push!(df, row)
    end
end

# reorder fsUsedSize to match order in file
df = df[!, [setdiff(names(df), ["fsUsedSize", "lang"]); "fsUsedSize"; "lang"]]

Ts = df |> eachcol .|> eltype .|> nonmissingtype

open("query_speed.js.out") do io
    for line in readlines(io)
        if !any(startswith.(line, collect("{} ")))
            global row = split(line, ' ')[[1, 3, 5, 7]]
        elseif startswith(line, ' ')
            key, val, = strip.(split(line, [':', ',']))
            key ∈ names(df) && push!(row, val)
        elseif startswith(line, '}')
            row = [parse(T,v) for (v,T) in zip(row, Ts)]
            push!(df, [row; "js"])
        end
    end
end

dfs = stack(df, Not([:lang, :N])) |> dropmissing

plts = [plot(df, x=:N, y=c, color=:lang) for c in setdiff(names(df), ["lang", "N"])]

set_default_plot_size(10cm, 100cm)
plt = vstack(plts)

import Cairo, Fontconfig
draw(PDF("query_speed.pdf"), plt)

