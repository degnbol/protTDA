#!/usr/bin/env julia
using GZip
using JSON3
using BSON, BSONqs, LightBSON

d0s = readdir("PH"; join=true)
d0  = d0s[1]
d1s = readdir(d0; join=true)
d1  = d1s[1]
fnames = readdir(d1)
fnames = fnames[startswith.(fnames, "AF")]

fname = fnames[1]

function readPH(d1, fname)
    GZip.open(joinpath(d1, fname)) do io
        d = JSON3.read(io, Dict)
        d["acc"] = split(fname, '-')[2]
        d
    end
end

@time d = readPH.(d1, fname)
@time ds = readPH.(d1, fnames)

