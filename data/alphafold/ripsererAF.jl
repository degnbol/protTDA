#!/usr/bin/env julia
using PyCall
@pyinclude "fetch.py"
using Ripserer
using JSON
using GZip
# https://www.lucidchart.com/techblog/2019/12/06/json-compression-alternative-binary-formats-and-compression-methods/
# using CodecXz
using SparseArrays
using LinearAlgebra # norm and normalize etc

function blob2PC(blob::PyObject)
    PC = Tuple{Float64,Float64,Float64}[]
    fh = blob.open()
    for line in fh
        startswith(line, "ATOM") || continue
        l = split(line)
        l[4] == "CA" || continue
        push!(PC, (parse(Float64,l[11]), parse(Float64,l[12]), parse(Float64,l[13])))
    end
    fh.close()
    PC
end

PC2PH(PC::Vector{Tuple{Float64,Float64,Float64}}) = ripserer(Alpha(PC); dim_max=2, alg=:involuted)

barcodes(PH, dim::Int) = hcat(collect.(collect(PH[dim+1]))...)'
representatives(PH, dim::Int) = [[collect(r.simplex) for r in collect(c)] for c in representative.(PH[dim+1])]

function representatives2H(reps::Vector{Vector{Vector{Int}}}, n::Int)
    Is = [n for    r  in           reps  for e in r for n in e]
    Js = [j for (j,r) in enumerate(reps) for e in r for n in e]
    sparse(Is, Js, true, n, length(reps))
end

"""
Taken from centrality_tools.jl in repo node-edge-hypergraph-centrality.
fgϕψs defined according to the max method (see Tudisco et al. 2021)
"""
function centralities(B; maxiter::Int=100, tol::Float64=1e-6,
        edge_weights::Vector{Float64}=ones(size(B,2)),
        node_weights::Vector{Float64}=ones(size(B,1)))
    
    # f is omitted since it is identity function
    g = x->x .^ (1/ 5)
    ϕ = x->x .^    15
    ψ = x->x .^ (1/15)
                
    n,m = size(B)
        
    x0 = fill(1/n, n)
    y0 = fill(1/m, m)
    
    W = spdiagm(edge_weights)
    N = spdiagm(node_weights)
     
    for _ in 1:maxiter
        x = normalize(sqrt.(x0 .* g(B  * W *   y0 )), 1)
        y = normalize(sqrt.(y0 .* ψ(B' * N * ϕ(x0))), 1)
        
        norm(x-x0,1) + norm(y-y0,1) < tol && return x, y
        
        x0 = x
        y0 = y
    end
    x0, y0
end


for blob in py"gen_blobs"o()
    # discard "AF-" ... "-model_v3.cif"
    name = blob.name[4:end-13]
    outdir = "PH/"*name[1:2]*"/"*name[3:4]
    outfile = outdir*"/"*name*".json.gz"
    isfile(outfile) && continue
    mkpath(outdir)
    touch(outfile)
    PC = blob2PC(blob)
    n = length(PC)
    println(name, " ", n)
    PH = PC2PH(PC)
    b1 = barcodes(PH,1)
    b2 = barcodes(PH,2)
    # persistence
    p1 = b1[:,2]-b1[:,1]
    p2 = b2[:,2]-b2[:,1]
    r1 = representatives(PH,1)
    r2 = representatives(PH,2)
    H1 = representatives2H(r1, n)
    H2 = representatives2H(r2, n)
    # only use node cent since edge cent is too similar to persistence
    cent1 = centralities(H1; edge_weights=p1)[1]
    cent2 = centralities(H2; edge_weights=p2)[1]
    dic = Dict(:n => n,
               :x => [p[1] for p in PC],
               :y => [p[2] for p in PC],
               :z => [p[3] for p in PC],
               :H1 => Dict(:barcode => b1, :representatives => r1),
               :H2 => Dict(:barcode => b2, :representatives => r2),
               :cent1 => cent1,
               :cent2 => cent2,
              )
    GZip.open(outfile, "w") do io JSON.print(io, dic) end
end
