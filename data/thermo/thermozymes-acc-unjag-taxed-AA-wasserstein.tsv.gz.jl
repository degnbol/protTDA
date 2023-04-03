#!/usr/bin/env julia
using JSON3, GZip
using CSV, DataFrames
using Ripserer
using Ripserer: Wasserstein, PersistenceDiagram

df = CSV.read("thermozymes-acc-unjag-taxed.tsv.gz", DataFrame)

readPH(path::String) = GZip.open(path) do io
    JSON3.read(read(io), Dict)
end

phs = readPH.(df.path)

function diagram(ph::Dict, dim::Int)
    bars = zip(Vector{Vector{Float64}}(ph["bars$dim"])...)
    bars = [(b,d) for (b,d) in bars if d-b>1.]
    PersistenceDiagram(collect(bars); dim=dim)
end

diagrams1 = diagram.(phs, 1)
diagrams2 = diagram.(phs, 2)

function wassersteins(diagrams)
    n = length(diagrams)
    wstn = Wasserstein()
    dists = zeros(n, n)
    for i in 1:n
        for j in i+1:n
            print("$i/$n $j/$n\r")
            dists[i, j] = wstn(diagrams[i], diagrams[j])
        end
    end
    dists
end


dsts1 = wassersteins(diagrams1)
# takes a lot of time even with the persistence filter




