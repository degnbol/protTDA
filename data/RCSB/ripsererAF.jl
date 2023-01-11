#!/usr/bin/env julia
using CrystalInfoFramework
using JSON
using GZip
using Ripserer
using SparseArrays
using LinearAlgebra # norm and normalize etc
using Random
using DataFrames

"""
Extract each chain in the CIF that has a sequence with an accession.
Only extract alpha carbons, i.e. the main carbon atom for each residue.
Only use chains with a single uniprot accession associated.
"""
function readCIF(path::String)
    lines = if endswith(path, ".gz")
        GZip.open(path) do io readlines(io) end
    else
        open(path) do io readlines(io) end
    end
    nc = Cif(join(lines, '\n'))     
    # there should only be a pair PDB id => Cif
    cif = only(nc).second
    title = only(cif["_entry.id"])
    
    # _struct_ref.id: integer (as string) id for a sequence from a 
    # single source (single uniprot accession).
    # _struct_ref.entity_id: integer (as string) id for one or more 
    # sequences glued together that will be assigned to one or more of 
    # the chains.
    
    # for simplicity we only use chains with a single associated 
    # accession.
    accessions = cif["_struct_ref.pdbx_db_accession"]
    seq_ids = cif["_struct_ref.entity_id"]
    # either uniprot accession or just the PDB id
    isAccession = cif["_struct_ref.db_name"] .== "UNP"
    any(isAccession) || return title, NamedTuple[]
    accessions = accessions[isAccession]
    seq_ids = seq_ids[isAccession]
    seq_id2acc = Dict{String,String}()
    for seq_id in unique(seq_ids)
        accession = accessions[seq_id .== seq_ids] |> unique
        if length(accession) == 1
            seq_id2acc[seq_id] = accession |> only
        end
    end
    # if all chains are hybrids made up of multiple accessions.
    length(seq_id2acc) > 0 || return title, NamedTuple[]
    
    df = DataFrame([parse.(Float64, cif["_atom_site.Cartn_$axis"]) for axis in "xyz"], [:x, :y, :z])
    df.isAtom = cif["_atom_site.group_PDB"] .== "ATOM"
    df.atomLabel = rstrip.(cif["_atom_site.label_atom_id"], ''')
    df.isCarbonAlpha = (df.atomLabel .== "CA") .|| (df.atomLabel .== "C1") 
    df.chain = cif["_atom_site.label_asym_id"]
    df.model = cif["_atom_site.pdbx_PDB_model_num"]
    df.resi = cif["_atom_site.label_seq_id"] # may contain ::Nothing for hetatom
    df.accession = cif["_atom_site.label_entity_id"] # replace with actual acc after row filter
    df.alt = cif["_atom_site.label_alt_id"] 
    df.occupancy = parse.(Float64, cif["_atom_site.occupancy"])
    df = df[df.isAtom .& df.isCarbonAlpha .& (df.accession .∈ Ref(keys(seq_id2acc))), :]
    df.resi = parse.(Int, df.resi)
    df.accession = [seq_id2acc[i] for i in df.accession]
    
    # May contain repeated entries with alt location.
    gdf = groupby(df, [:chain, :model, :resi, :accession])
    # For e.g. 2p3d the occupancy doesn't sum to chain A model 1 resi 35 atom 
    # without alt. We simply normalize to make sure weight is always summing to 
    # 1 for each atom.
    # weighted average xyz by occupancy
    df[!, [:x, :y, :z]] .*= df.occupancy
    df = combine(gdf, [:x, :y, :z, :occupancy] .=> sum; renamecols=false)
    df[!, [:x, :y, :z]] ./= df.occupancy
    
    structures = NamedTuple[]
    for ss in groupby(df, [:chain, :model, :accession])
        chain = only(unique(ss.chain))
        model = only(unique(ss.model))
        accession = only(unique(ss.accession))
        # should be in order but may start with an offset.
        @assert ss.resi == sort(ss.resi) ss.resi
        # Will be skipping values, e.g. if they are mutated.
        # Only use it if that is not the case.
        if ss.resi != ss.resi[end]-length(ss.resi)+1 : ss.resi[end]
            @warn "Sequence with gaps: $path chain=$chain accession=$accession"
            continue
        end
        xyzs = ss[!, [:x, :y, :z]] |> eachrow .|> Tuple{Float64,Float64,Float64}
        push!(structures, (chain=chain, model=model, accession=accession, position=ss.resi[begin], xyzs=xyzs))
    end
    
    title, structures
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

function cifPH(infname::String, outdir::String)
    name, structures = readCIF(infname)
    length(structures) > 0 || @warn "No valid point clouds found: $infname"
    
    for structure in structures
        chain = structure.chain
        model = structure.model
        accession = structure.accession
        PC = structure.xyzs
        
        n = length(PC)
        if n < 5
            # an error will be thrown by ripserer like:
            # "Not enough points ($n) to construct initial simplex (need 5)"
            @warn "Too few points ($n<5): $infname chain=$chain accession=$accession"
            return
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
        outfname = joinpath(outdir, lowercase(name)*"_$(chain)_$model-$accession.json.gz")
        @info "Writing $outfname"
        GZip.open(outfname, "w") do io
            JSON.print(io, Dict(
                                :n => n,
                                :pos => structure.position,
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
end

WORK = "../alphafold/dl/RCSB"
cif_paths = [p for d1 in readdir("$WORK/mmCIF/"; join=true) for p in readdir(d1; join=true)]
println(length(cif_paths), " cifs")

mkpath("$WORK/PH")
compl = vcat([readdir(d1) for d1 in readdir("$WORK/PH"; join=true)]...)
println(length(compl), " completed")

PDBs = [basename(p)[1:4] for p in cif_paths]
compl = [basename(p)[1:4] for p in compl]
todo = setdiff(PDBs, compl) |> shuffle
println(length(todo), " todo")


for _ in 1:10
    for PDB in todo[1:min(1000,length(todo))]
        # same system as they use, i.e. two middle chars are the folder.
        d1 = PDB[2:3]
        outdir = "$WORK/PH/$d1"
        mkpath(outdir)
        inprog = joinpath(outdir, "$PDB.inprogress")
        isfile(inprog) && continue
        touch(inprog)
        println(PDB)
        infname = "$WORK/mmCIF/$d1/$PDB.cif.gz"
        cifPH(infname, outdir)
        # rm(inprog) # if we only check for the inprog, and delete it we will 
        # keep overwriting old work and keep trying PDBs that didn't produce 
        # any results.
    end
end
