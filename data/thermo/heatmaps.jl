#!/usr/bin/env julia
using CSV, DataFrames
using Gadfly

df_tax = CSV.read("thermozymes-acc-unjag-taxed.tsv.gz", DataFrame)
df_ws1 = CSV.read("wassersteins1.tsv.gz", DataFrame)
df_ws2 = CSV.read("wassersteins2.tsv.gz", DataFrame)

df_ws1.accA = names(df_ws1)

df_ws1_st = stack(df_ws1, Not(:accA); variable_name=:accB)

# plot(df_ws1_st, x=:accA, y=:accB, Geom.histogram2d)

