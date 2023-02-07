#!/usr/bin/env julia
# should work, but the python script of the same name is faster since it uses 
# sparql
ROOT = `git root` |> readchomp
include("$ROOT/src/util/dataframes.jl")
include("$ROOT/src/util/fetchseq.jl")

df = loadtsv(stdin)
df = loadtsv("peptidases-TEMPURA-AF.tsv.gz")
df_seq = df[!,[:accession]] |> unique
df_seq.seqs = fetchseqs(df_seq.accession)
CSV.write(stdout, df_seq; delim='\t')
