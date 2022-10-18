#!/usr/bin/env julia
using Ripserer
using JSON
using GZip
using SparseArrays
using LinearAlgebra # norm and normalize etc
using Random

function cif2PC(fname::String)
    PC = Tuple{Float64,Float64,Float64}[]
    GZip.open(fname, "rt") do io
        lines = readlines(io)
        lines = lines[startswith.(lines, "ATOM")]
        for line in lines
            l = split(line)
            l[4] == "CA" || continue
            push!(PC, (parse(Float64,l[11]), parse(Float64,l[12]), parse(Float64,l[13])))
        end
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
        
        norm(x-x0,1) + norm(y-y0,1) < tol && return x
        
        x0 = x
        y0 = y
    end
    x0
end

compl = vcat([readdir(d2) for d1 in readdir("PH"; join=true) for d2 in readdir(d1; join=true)]...)
# strip extensions
compl = [f[1:end-8] for f in compl]
println(length(compl), " completed")

cifs = readdir("structures/proteomes/")
cifs = cifs[endswith.(cifs, ".cif.gz")]
# strip AF- and -model_v3.cif.gz
cifs = [f[4:end-16] for f in cifs]
println(length(cifs), " cifs")

todo = setdiff(cifs, compl) |> shuffle
println(length(todo), " todo")

for name in todo
    outdir = "PH/"*name[1:2]*"/"*name[3:4]
    outfile = outdir*"/"*name*".json.gz"
    isfile(outfile) && continue
    mkpath(outdir)
    touch(outfile)
    PC = try cif2PC("structures/proteomes/AF-$name-model_v3.cif.gz")
    catch
        println("problem reading structures/proteomes/AF-$name-model_v3.cif.gz")
        continue
    end
    n = length(PC)
    println(name, " ", n)
    n > 0 || continue
    PH = PC2PH(PC)
    b1 = barcodes(PH,1)
    b2 = barcodes(PH,2)
    r1 = representatives(PH,1)
    r2 = representatives(PH,2)
    dic = Dict(:n => n,
               :x => [p[1] for p in PC],
               :y => [p[2] for p in PC],
               :z => [p[3] for p in PC],
               :H1 => Dict(:barcode => b1, :representatives => r1),
               :H2 => Dict(:barcode => b2, :representatives => r2),
              )
    # add centralities unless trivial
    if size(b1,1) > 0 dic[:cent1] = centralities(rep2H(r1, n); edge_weights=b1[:,2]-b1[:,1]) end
    if size(b2,1) > 0 dic[:cent2] = centralities(rep2H(r2, n); edge_weights=b2[:,2]-b2[:,1]) end
    GZip.open(outfile, "w") do io JSON.print(io, dic) end
end
