#!/usr/bin/env julia
# import into other scripts to get a acc2path dataframe for joining onto other 
# tables to annotate paths for accessions of interest.
# Takes a few minutes to run.
using DataFrames

d2s = [d2 for d1 in readdir("PH"; join=true) for d2 in readdir(d1; join=true)]
fnames = vcat(readdir.(d2s; join=true)...)
names = basename.(fnames)
accs = [name[4:end-20] for name in names]

acc2path = DataFrame(accession=accs, path=fnames)

