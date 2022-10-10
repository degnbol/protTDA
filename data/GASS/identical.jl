#!/usr/bin/env julia
using JSON

fnames_regular = readdir("PHH2/")
fnames_mine = readdir("PHH2m/")

fnames_incommon = intersect(fnames_regular, fnames_mine)

for fname in fnames_incommon
    regular = JSON.parsefile("PHH2/$fname")
    mine = JSON.parsefile("PHH2m/$fname")
    @assert all(Vector{Vector{Float64}}(regular["barcode"])[1] .≈ Vector{Vector{Float64}}(mine["H1"]["barcode"])[1])
    @assert all(Vector{Vector{Float64}}(regular["barcode"])[2] .≈ Vector{Vector{Float64}}(mine["H1"]["barcode"])[2])
    @assert all(Vector{Vector{Float64}}(regular["barcode_2"])[1] .≈ Vector{Vector{Float64}}(mine["H2"]["barcode"])[1])
    @assert all(Vector{Vector{Float64}}(regular["barcode_2"])[2] .≈ Vector{Vector{Float64}}(mine["H2"]["barcode"])[2])
    @assert all(Vector{Vector{Vector{Int}}}(regular["representatives"]) .== Vector{Vector{Vector{Int}}}(mine["H1"]["representatives"]))
    @assert all(Vector{Vector{Vector{Int}}}(regular["representatives_2"]) .== Vector{Vector{Vector{Int}}}(mine["H2"]["representatives"]))
end

# they are identical, the floats within rounding error

