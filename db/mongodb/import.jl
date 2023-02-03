#!/usr/bin/env julia
# Example run:
# ./import.jl /home/opc/protTDA/data/alphafold/PH/100
using Mongoc; mg = Mongoc
using GZip

"""
Read gzipped PH JSON into a mongo document (BSON).
Additionally add:
 - the accession taken from path as the _id property.
   https://www.mongodb.com/docs/manual/core/document/#field-names
 - persistence
"""
function read_PH_json(path::String)
    acc = split(basename(path), '-')[2]
    doc = GZip.open(path) do io
        readlines(io) |> only |> mg.BSON
    end
    doc["_id"] = acc
    doc["pers1"] = doc["bars1"][2] .- doc["bars1"][1]
    doc["pers2"] = doc["bars2"][2] .- doc["bars2"][1]
    doc
end

client = mg.Client()
db = client["protTDA"]
mg.get_collection_names(db)
af = db["AF"]
# length(af)
# mg.drop(af)

# debug
d1 = "/home/opc/protTDA/data/alphafold/PH/100"
# d1, = ARGS
dirs = readdir(d1; join=true)
# dir = dirs[2] # debug
@time for dir in dirs
    fnames = readdir(dir; join=true)
    fnames = fnames[startswith.(basename.(fnames), "AF")]

    append!(af, read_PH_json.(fnames))
end
println(d1)

