#!/usr/bin/env julia
"""
Usage: ./mmCIF2tsv.jl INFILE(S)
Writes TSV(s) in the same folder where the infiles are found, with naming pattern:
name_CHAIN_model-ACCESSION.tsv
e.g. 5zqf_A_1-Q02880.tsv
Does not overwrite by default.
"""

using CrystalInfoFramework, GZip
using CSV, DataFrames


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
    accessions = try cif["_struct_ref.pdbx_db_accession"]
    catch; cif["_struct_ref_seq.pdbx_db_accession"] # assume KeyError
    end
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
    # NOTE: difference to code used for mmCIFs from AF. They all start with 1 so is simpler.
    # We used field _atom_site.label_seq_id for those, which starts at 1. Here we use the auth version, which is for the residue in the sequence.
    df.resi = cif["_atom_site.auth_seq_id"] # may contain ::Nothing for hetatom
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
            @info "Sequence with gaps: $path chain=$chain accession=$accession"
        end
        push!(structures, (chain=chain, model=model, accession=accession, resi=ss.resi, x=ss.x, y=ss.y, z=ss.z))
    end
    
    title, structures
end

for infname in ARGS
    dir = dirname(infname)
    bname = basename(infname)
    name, structures = readCIF(infname)
    # name, structures = try readCIF(infname)
    # catch;
    #     @error "Problem reading mmCIF"
    #     continue
    # end
    length(structures) > 0 || @warn "No valid point clouds found: $infname"
    for st in structures
        outfname = joinpath(dir, lowercase(name)*"_$(st.chain)_$(st.model)-$(st.accession).tsv")
        if isfile(outfname)
            @info "File $outfname already exists. Not overwriting."
            continue
        end
        df = DataFrame(; st...)[!, [:resi, :x, :y, :z]]
        CSV.write(outfname, df; delim='\t')
    end
end

