#!/usr/bin/env julia
include("format.jl")
include("request.jl")

"""
Will raise an error if accession format is wrong 
and return an empty sequence string if the accession is obsolete etc.
"""
function fetchseq(accession::AbstractString)::String
    url = "https://rest.uniprot.org/uniprotkb/$accession?format=fasta"
    body = request(url).body |> String
    # discard header
    split(body, '\n')[2:end] |> join
end
"""
Progress print.
"""
function fetchseqs(accessions::Vector{<:AbstractString})::Vector{String}
    seqs = String[]
    N = length(accessions)
    nDec = N |> string |> length
    fmt = "%$(nDec)d/$N\r"
    for (i, accession) in enumerate(accessions)
        format(fmt, i) |> print
        push!(seqs, fetchseq(accession))
    end
    println()
    seqs
end

