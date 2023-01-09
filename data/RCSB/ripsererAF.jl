#!/usr/bin/env julia
using JSON
using GZip
using Ripserer
using SparseArrays
using LinearAlgebra # norm and normalize etc
using Random

function cif2PC(lines::Vector{String})
    PC = Tuple{Float64,Float64,Float64}[]
    lines = lines[startswith.(lines, "ATOM")]
    for line in lines
        l = split(line)
        l[4] == "CA" || continue
        push!(PC, (parse(Float64,l[11]), parse(Float64,l[12]), parse(Float64,l[13])))
    end
    PC
end

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

"""
Taken from centrality_tools.jl in repo node-edge-hypergraph-centrality.
fgϕψs defined according to the max method (see Tudisco et al. 2021).
Modified to only return node centralities since edge centralities were 
too similar to the input persistences.
Modified to return zeros for trivial input.
"""
function centralities(B; maxiter::Int=100, tol::Float64=1e-6,
        edge_weights::Vector{Float64}=ones(size(B,2)),
        node_weights::Vector{Float64}=ones(size(B,1)))
    
    # f is omitted since it is identity function
    g = x->x .^ (1/ 5)
    ϕ = x->x .^    15
    ψ = x->x .^ (1/15)
                
    n,m = size(B)
    m > 0 || return zeros(n)
        
    x0 = fill(1/n, n)
    y0 = fill(1/m, m)
    
    W = spdiagm(edge_weights)
    N = spdiagm(node_weights)
     
    for _ in 1:maxiter
        x = normalize(sqrt.(x0 .* g(B  * W *   y0 )), 1)
        y = normalize(sqrt.(y0 .* ψ(B' * N * ϕ(x0))), 1)
        
        norm(x-x0,1) + norm(y-y0,1) < tol && return x
        
        x0 = x
        y0 = y
    end
    x0
end

function cifPH(infname::String, outfname::String)
    PC = GZip.open(infname) do io cif2PC(readlines(io)) end
    n = length(PC)
    PH = PC2PH(PC)
    b1 = barcodes(PH,1)
    b2 = barcodes(PH,2)
    r1 = representatives(PH,1)
    r2 = representatives(PH,2)
    # edge_weights=persistences
    cent1 = centralities(rep2H(r1, n); edge_weights=b1[:,2]-b1[:,1])
    cent2 = centralities(rep2H(r2, n); edge_weights=b2[:,2]-b2[:,1])
    GZip.open(outfname, "w") do io
        JSON.print(io, Dict(:n => n,
               :x => Float64[p[1] for p in PC],
               :y => Float64[p[2] for p in PC],
               :z => Float64[p[3] for p in PC],
               :bars1 => b1, 
               :bars2 => b2, 
               :reps1 => r1,
               :reps2 => r2,
               :cent1 => cent1,
               :cent2 => cent2,
              ))
    end
end

WORK = "../alphafold/dl/RCSB"
cif_paths = [p for d1 in readdir("$WORK/mmCIF/"; join=true) for p in readdir(d1; join=true)]
println(length(cif_paths), " cifs")

mkpath("$WORK/PH")
compl = vcat([readdir(d1) for d1 in readdir("$WORK/PH"; join=true)]...)
println(length(compl), " completed")

names = [basename(p)[1:4] for p in cif_paths]
todo = setdiff(names, compl) |> shuffle
println(length(todo), " todo")


for PDB in todo[1:min(1000,length(todo))]
    # same system as they use, i.e. two middle chars are the folder.
    d1 = PDB[2:3]
    outfname = "$WORK/PH/$d1/$PDB.json.gz"
    mkpath(dirname(outfname))
    isfile(outfname) && continue
    touch(outfname)
    println(PDB)
    cifPH("$WORK/mmCIF/$d1/$PDB.cif.gz", outfname)
end

