#!/usr/bin/env julia
using DataFrames, CSV

df = CSV.read("./uniprotkb_topoisomerase_AND_reviewed_tr_2024_07_07.tsv.gz", DataFrame; delim='\t')

df = df[startswith.(df[!, "Entry Name"], "TOP"), Not(:Reviewed)]


