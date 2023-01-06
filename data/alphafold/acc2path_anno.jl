#!/usr/bin/env julia
# use acc2path to find alphafold PH jsons for a table with a column "accession" 
# and write a new tsv with -AF suffix (before extensions) with a new column 
# "path" pointing to the relevant PH json.

# USAGE:
# include("$ROOT/data/alphafold/acc2path_anno.jl")
# df = annoAF("FILENAME.tsv.gz")

using DataFrames, CSVFiles
using GZip
ROOT = readchomp(`git root`)

# generate acc2path::DataFrame with columns :accession, :path
# WARNING: takes a long time. Make sure the .tsv can be read first, e.g. has 
# the "accession" column.
@isdefined(acc2path) || include("$ROOT/data/alphafold/acc2path.jl")

function annoAF(filename::String)
    # '\\' is a hack. I want to simply disable quotechar but that isn't 
    # possible so I set it to a char that isn't present in the file.
    # I want to disable it since there are quotes in the files and they shouldn't 
    # be used in any special way.
    df = load(File(format"TSV", filename); quotechar='\\') |> DataFrame
    nrow(df) > 0 || error("Empty file \"$filename\"")
    
    leftjoin!(df, acc2path, on=:accession)
    unique!(df)
    
    if endswith(filename, ".tsv.gz")
        outfile = filename[1:end-length(".tsv.gz")] * "-AF.tsv.gz"
    else
        outfile = filename[1:end-length(".tsv")] * "-AF.tsv"
    end
    save(File(format"TSV", outfile), df; quotechar=nothing, nastring="")
    
    df
end

