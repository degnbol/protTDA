#!/usr/bin/env julia
using LibPQ, DataFrames
using HDF5, H5Zzstd #, H5Zlz4, H5Zblosc
# countmap is MUCH faster than doing maximum(sum(a .== i) for i in 1:n)
using StatsBase: mean, countmap
using Random: shuffle!

"""
Insert a DataFrame into a postgres database with connection "conn".
"""
function pqinsert(conn, df::DataFrame)
    copyin = LibPQ.CopyIn("COPY AF FROM STDIN (FORMAT CSV);", join.(eachrow(df), ',') .* '\n')
    execute(conn, copyin)
end

ROOT = `git root` |> readchomp
cd("$ROOT/data/alphafold")

LibPQ.Connection("dbname=protTDA") do conn
    for _ in 1:100
        todo = setdiff(readdir("PH/h5"), readdir("PH/pgh5") .* ".h5")
        println(length(todo), " left")
        shuffle!(todo)
        batchsize = min(length(todo),10000)
        for (i_batch, h5) in enumerate(todo[1:batchsize])
            logfile = "PH/pgh5/" .* splitext(h5)[1]
            isfile(logfile) && continue
            touch(logfile)
            print("$i_batch/$batchsize\r")

            h5open("PH/h5/$h5") do fid
                n = length(fid)

                df = DataFrame(:acc=>String[], :taxon=>Int[], :n=>Int[],
                               :maxRep1=>Int[], :maxRep2=>Int[],
                               :maxPers1=>Float32[], :maxPers2=>Float32[],
                               :meanPLDDT=>Float32[],
                               :nRep1=>Int[], (Symbol("nRep1_t$i")=>Int[] for i in 1:10)...,
                               :nRep2=>Int[], (Symbol("nRep2_t0$i")=>Int[] for i in 1:9)..., :nRep2_t1=>Int[])

                for (i, acc) in enumerate(keys(fid))
                    g = fid[acc]
                    a = attrs(g)
                    pLDDT = g["Cas"][:,4]
                    pers1 = g["bars1"][:,2]
                    pers2 = g["bars2"][:,2]
                    repid1 = g["reps1"][:,1]
                    repid2 = g["reps2"][:,1]
                    push!(df, (acc, a["tax"], a["n"],
                               maximum(values(countmap(repid1)); init=0),
                               maximum(values(countmap(repid2)); init=0),
                               try pers1[end] catch; 0 end,
                               try pers2[end] catch; 0 end,
                               mean(pLDDT),
                               length(pers1), (sum(pers1 .> i) for i in 1.:10.)...,
                               length(pers2), (sum(pers2 .> i) for i in .1:.1:1.)...,
                              ))
                end

                pqinsert(conn, df)
            end
            open(logfile, "w") do io println(io, "complete") end
        end
    end
end
