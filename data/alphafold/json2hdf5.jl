#!/usr/bin/env julia
using HDF5, H5Zlz4, H5Zzstd, H5Zblosc
using GZip
using JSON3
ROOT = readchomp(`git root`)
include("$ROOT/src/util/tar.jl")

# USE: ./json2hdf5.jl [INDIR/]
# Without INDIR it takes a random top level, like:
# E.G. ./json2hdf5.jl PH/391
# E.G. ./json2hdf5.jl PH/391/391366-0
dProteome = "$ROOT/data/proteomes" #/proteome-tax_id-391366-0_v3.tar
outdir = "$ROOT/data/alphafold/PH/hdf5"
indir = ARGS

if length(indir) > 0
    @assert length(indir) == 1
    indir, = indir
    tmpfile = "h5temp/lars"
else
    using Random
    # assuming we keep a record at h5temp
    todo = readdir("PH")
    todo = todo[startswith.(todo, r"[0-9]")]
    compl = readdir("h5temp")
    todo = setdiff(todo, compl)
    indir = rand(todo)
    tmpfile = "h5temp/$indir"
    # touch(tmpfile)
    indir = "PH/$indir"
    println(indir)
end

basedir = splitpath(indir)[end]
indir_contents = readdir(indir)
indir_fnames = indir_contents[startswith.(indir_contents, "AF-")]
if length(indir_fnames) > 0
    taxons = [basedir]
    indir_fnames = [joinpath.(indir, indir_fnames)]
else
    taxons = indir_contents[isdir.(joinpath.(indir, indir_contents))]
    indir_fnames = [readdir(d; join=true) for d in joinpath.(indir, taxons)]
    indir_fnames = [fnms[startswith.(basename.(fnms), "AF-")] for fnms in indir_fnames]
end

"""
Given a stream for a .cif file, extract the amino acid sequence.
"""
function cif2seq(io)::String
    while !eof(io)
        line = readline(io)
        # there's potential seq entries:
        # - _entity_poly.pdbx_seq_one_letter_code
        # - _entity_poly.pdbx_seq_one_letter_code_can
        # - _struct_ref.pdbx_seq_one_letter_code
        # I checked ~9k files in proteome-tax_id-100-0_v3.tar and they were 
        # identical in all so I assume identical in all AF.
        startswith(line, "_entity_poly.pdbx_seq_one_letter_code") || continue
        # either written on next lines terminated by ; or written on one line 
        # with whitespace in-between
        oneliner = split(line)
        length(oneliner) == 1 || return oneliner[2]
        seq = String[]
        # (only) the very first line of the seq starts with ;
        line = lstrip(readline(io), ';')
        # the seq is terminated with a line only containing semicolon
        while line != ";"
            push!(seq, line)
            line = readline(io)
        end
        return join(seq)
    end
end

"""
Read sequences and pLDDT confidence scores from all proteins in a given proteome.
Return as mappings from accession to string and float32 vector.
"""
function read_proteome(taxon::String)
    # I have done various checks on 9k files to see that they always have 
    # indexes for amino acids in a perfect 1:n
    # and all entries ending in _begin or _beg equals 1 (such as 
    # _struct_ref_seq.pdbx_auth_seq_align_beg)
    # Also, the first ATOM entry has resi 1 in all 9k.
    # All residueNumber entries in the confidence_v3.json.gz files also started at 
    # 1 and the accession_ids.csv file on their ftp server has 1 for all 214M 
    # entries.
    proteome = "$dProteome/proteome-tax_id-$(taxon)_v3.tar"
    seqs = Dict{String,String}()
    pLDDTs = Dict{String,Vector{Float32}}()
    for (i, (path, io)) in enumerate(targzip(proteome))
        # print("$i\r")
        acc = split(path, '-')[2]
        if endswith(path, ".cif.gz")
            # get sequence
            seqs[acc] = cif2seq(io)
        elseif endswith(path, "confidence_v3.json.gz")
            # get pLDDT
            d = JSON3.read(io, Dict)
            pLDDTs[acc] = d["confidenceScore"]
        end
    end
    seqs, pLDDTs
end

filters = H5Zzstd.ZstdFilter()

for (t, (taxon, infnames)) in enumerate(zip(taxons, indir_fnames))
    tmpfile2 = "h5temp2/$taxon"
    isfile(tmpfile2) && continue
    touch("h5temp2/$taxon")
    print(stderr, "$t/$(length(taxons)) $taxon\n")
    
    @time begin
        seqs, pLDDTs = read_proteome(taxon);

        for (i_fname, fname) in enumerate(infnames)
            print(stderr, "$i_fname/$(length(infnames))\r")
            acc = split(basename(fname), '-')[2]
            accdir = joinpath(outdir, acc[1:5]) |> mkpath
            h5open(joinpath(accdir, acc * ".h5"), "w") do fid
                d = GZip.open(fname) do io
                    JSON3.read(io, Dict)
                end;
                # haskey(fid, acc) && continue
                # g = create_group(fid, acc)
                att = attrs(fid)
                att["tax"], att["taxv"] = parse.(Int32, split(taxon, '-'))
                att["n"] = d["n"]
                att["AA"] = seqs[acc]
                fid["Cas"] = hcat(d["x"], d["y"], d["z"], pLDDTs[acc], d["cent1"], d["cent2"]) .|> Float32
                bars1 = hcat(d["bars1"]...) |> Matrix{Float32}
                bars2 = hcat(d["bars2"]...) |> Matrix{Float32}
                bars1[:, 2] .-= bars1[:, 1] # death -> persistence
                bars2[:, 2] .-= bars2[:, 1] # death -> persistence
                fid["bars1"] = bars1
                fid["bars2"] = bars2
                reps1s = reduce.(hcat, d["reps1"]; init=zeros(Int32, 2, 0)) .|> Matrix{Int32}
                reps2s = reduce.(hcat, d["reps2"]; init=zeros(Int32, 3, 0)) .|> Matrix{Int32}
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
    end
    
    # note completion
    open(tmpfile2, "w") do io
        println(io, "complete")
    end
end

# note completion
open(tmpfile, "w") do io
    println(io, "complete")
end

