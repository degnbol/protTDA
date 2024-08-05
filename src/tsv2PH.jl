#!/usr/bin/env julia
"""
tsv2PH.jl INFILES... OUTDIR/
Reads uncompressed TSVs with one curve per file and assumed header containing "x", "y", "z".
Writes HDF5s with the same name to OUTDIR/.
Does not overwrite.
PH calculated with ripserer.jl using Alpha complexes in dimension 1 and 2.
Centrality calculation included.
"""

using Ripserer
using SparseArrays
using LinearAlgebra # norm and normalize etc
using CSV, DataFrames
using HDF5, H5Zzstd
filters = H5Zzstd.ZstdFilter()
ROOT = `git root` |> readchomp
include("$ROOT/src/util/centralities.jl") # fn centralities(B, ...)

PC2PH(PC::Vector{Tuple{Float64,Float64,Float64}}) = ripserer(Alpha(PC); dim_max=2, alg=:involuted)

function barcodes(PH, dim::Int)
    # use init for default 0×2 (after adjoint) output for trivial barcodes
    reduce(hcat, collect.(collect(PH[dim+1])); init=Matrix{Float64}(undef,2,0))'
end
function representatives(PH, dim::Int)::Vector{Vector{Vector{Int}}}
    [[collect(r.simplex) for r in collect(c)] for c in representative.(PH[dim+1])]
end

function rep2H(reps::Vector{Vector{Vector{Int}}}, n::Int)
    Is = [n for    r  in           reps  for e in r for n in e]
    Js = [j for (j,r) in enumerate(reps) for e in r for n in e]
    sparse(Is, Js, true, n, length(reps))
end

INFILES..., OUTDIR = ARGS
@assert isdir(OUTDIR) || !isfile(OUTDIR) "No OUTDIR provided: $OUTDIR"
mkpath(OUTDIR)

for infname in INFILES
    outfname = joinpath(OUTDIR, splitext(basename(infname))[1] * ".h5")
    if isfile(outfname)
        @info "File already exists: $outfname. Not overwriting."
        continue
    end

    df = CSV.read(infname, DataFrame; delim='\t')
    PC = df[!, [:x, :y, :z]] |> eachrow .|> Tuple

    n = length(PC)
    if n < 5
        # an error will be thrown by ripserer like:
        # "Not enough points ($n) to construct initial simplex (need 5)"
        @warn "Too few points ($n<5): $infname"
        continue
    end
    PH = try PC2PH(PC)
    catch e
        if e isa OverflowError
            @warn "Structure too large: $infname"
            return
        elseif e isa KeyError
            @warn "Ripserer KeyError bug: $infname"
        else
            rethrow(e)
        end
    end
    b1 = barcodes(PH,1)
    b2 = barcodes(PH,2)
    r1 = representatives(PH,1)
    r2 = representatives(PH,2)
    # edge_weights=persistences
    cent1 = centralities(rep2H(r1, n); edge_weights=b1[:,2]-b1[:,1])
    cent2 = centralities(rep2H(r2, n); edge_weights=b2[:,2]-b2[:,1])
    @info "Writing $outfname"
    h5open(outfname, "w") do fid
        att = attrs(fid)
        # att["tax"], att["taxv"] = parse.(Int32, split(taxon, '-'))
        att["n"] = n
        att["resi"] = df.resi
        # att["AA"] = seq # needs to be written into the TSVs
        # pLLDT no longer meaningful
        fid["Cas"] = hcat(df.x, df.y, df.z, fill(-1, n), cent1, cent2) .|> Float32
        bars1 = b1 |> Matrix{Float32}
        bars2 = b2 |> Matrix{Float32}
        bars1[:, 2] .-= bars1[:, 1] # death -> persistence
        bars2[:, 2] .-= bars2[:, 1] # death -> persistence
        fid["bars1"] = bars1
        fid["bars2"] = bars2
        reps1s = reduce.(hcat, r1; init=zeros(Int32, 2, 0)) .|> Matrix{Int32}
        reps2s = reduce.(hcat, r2; init=zeros(Int32, 3, 0)) .|> Matrix{Int32}
        reps1s = Int32[vcat(fill.(1:length(reps1s), size.(reps1s, 2))...) reduce(hcat, reps1s; init=zeros(Int32, 2, 0))']
        reps2s = Int32[vcat(fill.(1:length(reps2s), size.(reps2s, 2))...) reduce(hcat, reps2s; init=zeros(Int32, 3, 0))']
        try fid["reps1", filters=filters, chunk=size(reps1s)] = reps1s
        catch; fid["reps1"] = reps1s
        end
        try fid["reps2", filters=filters, chunk=size(reps2s)] = reps2s
        catch; fid["reps2"] = reps2s
        end
    end
end

