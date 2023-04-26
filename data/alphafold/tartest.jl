#!/usr/bin/env julia
# using JSON3

ROOT = `git root` |> readchomp
include("$ROOT/src/util/tar.jl")

failed = 0
succes = 0

for dir in readdir("PH/MF"; join=true)
    fnames = readdir(dir; join=true)

    for fname in fnames
        succes += 1
        try
            for (h, io) in TarIterator(fname)
                if h.size == 0
                    failed += 1
                    succes -= 1
                    rm(fname)
                    break
                end
            end
        catch
            failed += 1
            succes -= 1
            rm(fname)
        end
        print("$failed\t$succes\r")
    end

end

