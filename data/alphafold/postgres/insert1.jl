#!/usr/bin/env julia
using LibPQ, DataFrames
using HDF5, H5Zzstd #, H5Zlz4, H5Zblosc
# countmap is MUCH faster than doing maximum(sum(a .== i) for i in 1:n)
using StatsBase: mean, countmap
using Random: shuffle!

pqtable(conn, query::String) = execute(conn, query) |> LibPQ.columntable

"""
Insert a DataFrame into a postgres database with connection "conn".
"""
function pqinsert(conn, df::DataFrame)
    copyin = LibPQ.CopyIn("COPY AF FROM STDIN (FORMAT CSV);", join.(eachrow(df), ',') .* '\n')
    execute(conn, copyin)
end
function pqinsert(conn, row::Tuple)
    copyin = LibPQ.CopyIn("COPY AF FROM STDIN (FORMAT CSV);", [join(row, ',') * '\n'])
    execute(conn, copyin)
end

"""
Return whether an acc id is in the table "af".
"""
function pqin(conn, acc::String)
    !isempty(execute(conn, "SELECT 1 FROM AF WHERE acc='$acc'"))
end
function pqin(conn, accs::Vector{String})
    acc_str = join(["'$acc'" for acc in accs], ',')
    pqtable(conn, "select acc from af where acc in ($acc_str)")[1]
end

ROOT = `git root` |> readchomp
cd("$ROOT/data/alphafold")

LibPQ.Connection("dbname=protTDA") do conn
    for _ in 1:1000
        todo = readdir("PH/pgh5")
        todo = todo[filesize.(joinpath.("PH/pgh5", todo)) .== 0] |> rand
        todos = readdir("PH/hdf5/$todo")
        if isempty(todos)
            open("PH/pgh5/$todo", "w") do io println(io, "complete") end
            continue
        end
        todos = [splitext.(fname)[1] for fname in todos]
        shuffle!(todos)
        println(length(todos), " left in ", todo)
        todos = todos[1:min(length(todos), 100000)]
        setdiff!(todos, pqin(conn, todos))
        batchsize = min(length(todos), 10000)
        for (i_batch, acc) in enumerate(todos[1:batchsize])
            i_batch % 100 == 0 && print("$i_batch/$batchsize\r")

            h5open("PH/hdf5/$todo/$acc.h5") do g
                a = attrs(g)
                pLDDT = g["Cas"][:,4]
                pers1 = g["bars1"][:,2]
                pers2 = g["bars2"][:,2]
                repid1 = g["reps1"][:,1]
                repid2 = g["reps2"][:,1]
                pqin(conn, acc) || pqinsert(conn, (acc, a["tax"], a["n"],
                                maximum(values(countmap(repid1)); init=0),
                                maximum(values(countmap(repid2)); init=0),
                                try pers1[end] catch; 0 end,
                                try pers2[end] catch; 0 end,
                                mean(pLDDT),
                                length(pers1), (sum(pers1 .> i) for i in 1.:10.)...,
                                length(pers2), (sum(pers2 .> i) for i in .1:.1:1.)...,
                               ))
            end
        end
    end
end
