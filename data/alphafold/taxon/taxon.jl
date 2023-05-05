#!/usr/bin/env julia
using DelimitedFiles
using CSV, DataFrames

dfd = CSV.read("categories.dmp", DataFrame; header=[:domain, :species, :tax])
# A = Archaea
# B = Bacteria
# E = Eukaryota
# V = Viruses and Viroids
# U = Unclassified
# O = Other
# most are species entries:
# sum(dfc.species .== dfc.tax)
dfd = dfd[!, Not(:tax)] |> unique
# use 3 main domains of life plus virus
dfd = dfd[occursin.(dfd.domain, Ref("ABEV")), :]

dfn = CSV.read("nodes.dmp", DataFrame; header=false, select=[1, 3, 5])
rename!(dfn, [:child, :parent, :rank])
df_ranks = rename(dfn[!, Not(:parent)], :child => :tax)

df_parent = [rename(dfn[!, Not(:rank)], :child => :tax)]
for lineage in 1:100
    push!(df_parent, innerjoin(rename(df_parent[end], :parent => :cmp),
                               rename(df_parent[1], :tax => :cmp); on= :cmp)[!, Not(:cmp)])
    any(df_parent[end][!, :parent] .!= 1) || break
end
println("longest lineage: ", length(df_parent))

dfp = vcat(df_parent...) |> unique

leftjoin!(dfp, df_ranks; on= :parent => :tax)
rename!(dfp, :rank => :rankp)
leftjoin!(dfp, df_ranks; on= :tax)
disallowmissing!(dfp)

# from https://en.wikipedia.org/wiki/Domain_(biology)
ranks = ["kingdom", "phylum", "class", "order", "family", "genus", "species"]

