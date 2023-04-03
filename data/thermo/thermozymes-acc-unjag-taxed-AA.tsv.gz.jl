#!/usr/bin/env julia
using CSV, DataFrames
ROOT = readchomp(`git root`)
include("$ROOT/src/util/tar.jl")
include("$ROOT/src/util/glob.jl")

dProteome = "$ROOT/data/proteomes" #/proteome-tax_id-391366-0_v3.tar

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
        line = lstrip(readline(io), ';')
        while line != ";"
            push!(seq, line)
            line = readline(io)
        end
        return join(seq)
    end
end

"""
Read an AA seq for a given protein in a given proteome.
"""
function readAA(taxon::Int, acc::T) where T<:AbstractString
    # I have done various checks on 9k files to see that they always have 
    # indexes for amino acids in a perfect 1:n
    # and all entries ending in _begin or _beg equals 1 (such as 
    # _struct_ref_seq.pdbx_auth_seq_align_beg)
    # Also, the first ATOM entry has resi 1 in all 9k.
    # All residueNumber entries in the confidence_v3.json.gz files also started at 
    # 1 and the accession_ids.csv file on their ftp server has 1 for all 214M 
    # entries.
    proteomes = "$dProteome/proteome-tax_id-$(taxon)-*_v3.tar" |> glob
    for proteome in proteomes
        for (path, io) in targzip(proteome, "AF-$(acc)-F1-model_v3.cif.gz")
            return cif2seq(io)
        end
    end
end

df = CSV.read("thermozymes-acc-unjag-taxed.tsv.gz", DataFrame)

#  too slow
# df.AA = [readAA(taxon, acc) for (taxon,acc) in eachrow(df[!, [:taxon, :acc]])]

