#!/usr/bin/env julia
using CSV, DataFrames
using Statistics

df_bounds = CSV.read("H2comm_boundaries.tsv.gz", DataFrame)[!, Not("indexCA")]
df_sites = CSV.read("CSA_sites.tsv", DataFrame)
df_bounds[!, "class"] .= "bound"
df_sites[!, "class"] .= "site"
df = vcat(df_bounds, df_sites)

dfg = groupby(df, ["RCSB", "chain"])
dfg = [g for g in dfg if !isempty(g[g[!, :class] .== "bound", :resi])]
dfg = [g for g in dfg if !isempty(g[g[!, :class] .== "site", :resi])]


function mindists(sites, bounds)
    minimum(abs.(sites .- bounds'); dims=2) |> vec
end

"""
Shift values n places while cycling around within a given range, e.g.
shift([3, 5, 7], 2:8, 4) -> [7, 2, 4]
"""
function shift(values, rang, n)
    (values .- rang.start .+ n) .% (rang.stop - rang.start + 1) .+ rang.start
end

min_dists = []
for g in dfg
    sites = g[g[!, :class] .== "site", :resi]
    bounds = g[g[!, :class] .== "bound", :resi]
    append!(min_dists, mindists(sites, bounds))
end

min_dists_rnd = []
for g in dfg
    sites = g[g[!, :class] .== "site", :resi]
    bounds = g[g[!, :class] .== "bound", :resi]
    # estimate range from observed min and max
    rang = min(sites..., bounds...):max(sites..., bounds...)
    # random selection alternative to bounds
    bounds = rand(rang, length(bounds))
    append!(min_dists_rnd, mindists(sites, bounds))
end

println(mean(min_dists .<= min_dists_rnd))


min_dists_shift = []
for g in dfg
    sites = g[g[!, :class] .== "site", :resi]
    bounds = g[g[!, :class] .== "bound", :resi]
    # estimate range from observed min and max
    rang = min(sites..., bounds...):max(sites..., bounds...)
    # random shift alternative to bounds
    bounds = shift(bounds, rang, rand(1:rang.stop-rang.start))
    append!(min_dists_shift, mindists(sites, bounds))
end

println(mean(min_dists .<= min_dists_shift))

