#!/usr/bin/env julia
using GZip, JSON
using Distances
using .Threads: @threads
ROOT = `git root` |> readchomp
include("$ROOT/src/util/dataframes.jl")
include("$ROOT/src/util/format.jl")

function readxyz(path::String)
    GZip.open(path) do io
        d = JSON.parse(io)
        hcat((d[k] for k in split("xyz", ""))...)
    end
end


df = loadtsv("../MEROPS/peptidases-TEMPURA-AF.tsv.gz")
df_seqs = loadtsv("peptidases-TEMPURA-AF-seqs.tsv.gz")

df = df[df.path .!= "NA", :]
df = innerjoin(df, df_seqs; on=:accession)
df.nCys .= -1
df.nCysClose .= -1

# When are two cysteines close enough to form a covalent bond?
# typical cysteine disulphide bonds are 2Å:
# https://doi.org/10.3389/fchem.2020.00280
# The distances in `dists` are between carbon alphas of the backbone.
# Cysteine has a side-chain Cα-C-S. A typical C-C bond is 1.54Å and 1.6Å for 
# C-S (Pure & Appl. Chem., Vol. 59, No. 8, p. 1057—1062, 1987.). The location 
# of atoms are unprecise since they are computed by alphafold and Cysteines are 
# rare ish in proteins (same citation) so we should allow for some extra 
# distance in determining if two cystein backbones are close:
thres = 2. + 2 * (1.54 + 1.6 + 2.)

N = nrow(df)
fmt = "%$(length(string(N)))d/$N\r"

@threads for i in 1:N
    format(fmt, i) |> print
    xyz = readxyz(joinpath("$ROOT/data/alphafold", df.path[i]))
    seq = df.AA[i] |> collect

    length(seq) == size(xyz,1) || continue

    Cs = xyz[seq .== 'C', :]
    nCys = size(Cs,1)
    dists = pairwise(Euclidean(), Cs; dims=1)
    # minus diagonal (each cys is close to itself) and divide by 2 since matrix 
    # is symmetrical.
    nClose = (sum(dists .< thres) - nCys) / 2
    df[i, [:nCys, :nCysClose]] .= [nCys, nClose]
end
println()

CSV.write("peptidases-TEMPURA-AF-seqs-cys.tsv.gz", df; delim='\t', compress=true)

