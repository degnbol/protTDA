#!/usr/bin/env julia
using CSV, DataFrames
using Statistics
using HypothesisTests
using Distributions
using Chain

df_resis = DataFrame()
for file in readdir("xyz/")
    df_resi = CSV.read(joinpath("xyz/", file), DataFrame)
    df_resi[!, "PDB"] .= splitext(file)[1]
    df_resi[!, "chain"] .= string.(df_resi.chain) # some have int
    append!(df_resis, df_resi)
end

df_bounds = CSV.read("Boundaries_metal.csv", DataFrame)[!, Not("index")]
df_metals = CSV.read("metal_sites.tsv", DataFrame)
df_bounds[!, "bound"] .= true;
df_metals[!, "metal"] .= true;

leftjoin!(df_resis, unique(df_bounds); on=["PDB", "chain", "resi"])
leftjoin!(df_resis, unique(df_metals); on=["PDB", "chain", "resi"])
df_resis = coalesce.(df_resis, false)


function inwindow(resi, bound; pad=0)
    any(bound) || return bound
    @chain resi .- resi[bound]' begin
        abs.()
        minimum(; dims=2)
        _ .<= pad
        vec
    end
end

df_cons = DataFrame()

for pad in 0:10
    df = @chain df_resis begin
        groupby([:PDB, :chain])
        transform([:resi, :bound] => ((r,b) -> inwindow(r,b; pad=pad)) => :inwin)
    end

    # confusion table
    df_con = @chain df begin
        groupby([:metal, :inwin])
        combine(nrow => :n)
        sort([:metal, :inwin]; rev=true)
    end
    df_con[!, :pad] .= pad

    P = sum(df_con[df_con.metal, :n])
    N = sum(df_con[.!df_con.metal, :n])
    TP = df_con[df_con.metal .& df_con.inwin, :n]
    FP = df_con[.!df_con.metal .& df_con.inwin, :n]
    trials = sum(df_con[df_con.inwin, :n])
    
    d = Hypergeometric(P, N, trials)
    p, = ccdf(d, df_con[df_con.metal .& df_con.inwin, :n])
    df_con[!, :p] .= p
    df_con[!, :sensitivity] .= TP / P
    df_con[!, :coverage] .= (TP + FP) / N
    
    append!(df_cons, df_con)
end

rename!(df_cons, Dict(:inwin => :near_boundary,
                      :n => :n_points,
                      :pad => :dist_threshold))
CSV.write("boundary_hyper.tsv", df_cons; delim='\t')

