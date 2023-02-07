#!/usr/bin/env julia
using DataFrames
# using FileIO
using CSV
using Chain: @chain

"""
Read a .tsv or .tsv.gz into a DataFrame while ignoring quote characters.
"""
function loadtsv(infile::Union{AbstractString,Base.PipeEndpoint})::DataFrame
    # not developed enough, gives an error on first call, then works on a 
    # second identical call for `peptidases-TEMPURA-AF.tsv.gz`
    # @chain infile File{format"TSV"}() load(; quotechar='\\') DataFrame
    # Had useless error about converting Missing to String, which I realized 
    # was caused by the same quoting related issue as why I write 
    # quotechar='\\' above.
    CSV.read(infile, DataFrame; delim='\t', quoted=false)
end

