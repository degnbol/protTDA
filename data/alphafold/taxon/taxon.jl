#!/usr/bin/env julia
using DelimitedFiles
using CSV, DataFrames
using Printf
using LibPQ

ROOT = `git root` |> readchomp
cd("$ROOT/data/alphafold/taxon")

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



# simplify tree to only contain the following ranks (plus domain):
# from https://en.wikipedia.org/wiki/Domain_(biology)
ranks = ["kingdom", "phylum", "class", "order", "family", "genus", "species"]

# create species dataframe which will be the lowest tax table.
# All children nodes and the species nodes themselves will be listed here and 
# the tax column will be used for joining onto accessions to calculate mean and 
# variance of protein values. If there are any proteins that only belong to 
# taxa higher than species they will be ignored. Even viruses belong to species 
# so I think it is fine. 
df_tree = dfp[dfp.rankp .== "species", :]
uSpecies = df_ranks[df_ranks.rank .== "species", :tax]
append!(df_tree, DataFrame(tax=uSpecies, parent=uSpecies, rank="species", rankp="species"))
df_tree = innerjoin(df_tree, dfd; on= :parent => :species)
df_left = unique(df_tree[!, [:parent, :domain]])

for rank in ranks[end-1:-1:1]
    df_append = dfp[dfp.rankp .== rank, :]
    df_append = innerjoin(df_append, df_left; on= :tax => :parent)
    df_left   = antijoin(df_left, df_append;  on= :parent => :tax)
    append!(df_left, unique(df_append[!, [:parent, :domain]]))
    append!(df_tree, df_append)
end

function get_rank_nrows(df)
    df = copy(df)
    df.rank[df.rank .∉ Ref(ranks)] .= ""
    df_nrow = combine(groupby(df, [:rank, :rankp]), nrow)
    sort!(df_nrow, [:rankp, :rank])
end

combine(groupby(df_tree, :domain), nrow) |> println
combine(groupby(df_tree, :rankp), nrow) |> println
df_nrow = get_rank_nrows(df_tree)
transform(groupby(df_nrow, :rankp), :nrow => (x -> x ./ sum(x)) => :nrow_frac) |> println

# traverse only the direct ranks in "ranks"
df_tf = df_tree[(df_tree.rankp .== "kingdom") .&& (df_tree.rank .== "phylum"), :]
for (parent, child) in zip(ranks[2:end-1], ranks[3:end])
    df_trav = df_tree[(df_tree.rankp .== parent) .&& (df_tree.rank .== child), :]
    df_trav = innerjoin(df_trav, df_tf[!, [:tax]]; on= :parent => :tax)
    append!(df_tf, df_trav)
end
append!(df_tf, df_tree[df_tree.rankp .== "species", :])

fracDirect = length(unique(df_tf.tax)) / length(unique(df_tree.tax))
@printf("%.3f%% of lower taxons would be covered with direct", fracDirect*100)
get_rank_nrows(df_tf) |> println

# sizes of varchar in postgres
df_tf.rank  |> unique .|> length |> maximum |> println
df_tf.rankp |> unique .|> length |> maximum |> println

"""
Insert a DataFrame into a postgres database with connection "conn".
"""
function pqinsert(conn, table::String, df::DataFrame)
    copyin = LibPQ.CopyIn("COPY $table FROM STDIN (FORMAT CSV);", join.(eachrow(df), ',') .* '\n')
    execute(conn, copyin)
end

LibPQ.Connection("dbname=protTDA") do conn
    # assuming that the table is created with create_taxtree.sql and empty.
    pqinsert(conn, "taxparent", dfp)
    pqinsert(conn, "taxtree", df_tree)
end

