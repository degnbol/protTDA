# BLAST+ Wrapper
# ==============
#
# Wrapper for BLAST+ command line functions.
#
# This file is a part of BioJulia.
# License is MIT: https://github.com/BioJulia/Bio.jl/blob/master/LICENSE.md
# https://github.com/BioJulia/BioTools.jl/blob/master/src/blast/blastcommandline.jl
using EzXML
using FilePaths

nc(xmlpath::String, obj) = EzXML.nodecontent(findfirst(xmlpath, obj))

"""
    readblastXML(blastrun::AbstractString)
Parse XML output of a blast run. Input is an XML string eg:
```julia
results = read(open("blast_results.xml"), String)
readblastXML(results)
```
Returns Vector{BLASTResult} with the sequence of the hit, the Alignment with query sequence, bitscore and expect value
"""
function readblastXML(blastrun::AbstractString; seqtype="nucl")
    dc = EzXML.parsexml(blastrun)
    rt = EzXML.root(dc)
    results = NamedTuple[]
    for iteration in findall("/BlastOutput/BlastOutput_iterations/Iteration", rt)
        queryname = nc("Iteration_query-def", iteration)
        for hit in findall("Iteration_hits", iteration)
            if EzXML.countelements(hit) > 0
                hitname = nc("./Hit/Hit_def", hit)
                hsps = findfirst("./Hit/Hit_hsps", hit)
                qseq = nc("./Hsp/Hsp_qseq", hsps)
                hseq = nc("./Hsp/Hsp_hseq", hsps)
                qfrom = parse(Int, nc("./Hsp/Hsp_query-from", hsps))
                qto   = parse(Int, nc("./Hsp/Hsp_query-to", hsps))
                hfrom = parse(Int, nc("./Hsp/Hsp_hit-from", hsps))
                hto   = parse(Int, nc("./Hsp/Hsp_hit-to", hsps))
                bitscore = parse(Float64, nc("./Hsp/Hsp_bit-score", hsps))
                expect = parse(Float64, nc("./Hsp/Hsp_evalue", hsps))
                push!(results, (
                    bitscore=bitscore,
                    expect=expect,
                    qrange=qfrom:qto,
                    hrange=hfrom:hto,
                    qseq=qseq,
                    hseq=hseq,
                    hit=nc("./Hit/Hit_def", hit)
                ))
            end
        end
    end
    return results
end

"""
`readblastXML(blastrun::Cmd)`
Parse command line blast query with XML output. Input is the blast command line command, eg:
```julia
blastresults = `blastn -query seq1.fasta -db some_database -outfmt 5`
readblastXML(blastresults)
```
Returns Vector{BLASTResult} with the sequence of the hit, the Alignment with query sequence, bitscore and expect value
"""
function readblastXML(blastrun::Cmd; seqtype="nucl")
    return readblastXML(read(blastrun, String), seqtype=seqtype)
end


"""
`blastn(query, subject, flags...)``
Runs blastn on `query` against `subject`.
    Subjects and queries may be file names (as strings), DNASequence type or
    Array of DNASequence.
    May include optional `flag`s such as `["-perc_identity", 95,]`. Do not use `-outfmt`.
"""
function blastn(query::AbstractPath, subject::AbstractPath, flags=[]; db::Bool=false)
    if db
        results = readblastXML(`blastn -query $query -db $subject $flags -outfmt 5`)
    else
        results = readblastXML(`blastn -query $query -subject $subject $flags -outfmt 5`)
    end
    return results
end

function blastn(query::String, subject::String, flags=[])
    querypath, subjectpath = makefasta(query), makefasta(subject)
    return blastn(querypath, subjectpath, flags)
end

function blastn(query::String, subject::Vector{String}, flags=[])
    querypath, subjectpath = makefasta(query), makefasta(subject)
    blastn(querypath, subjectpath, flags)
end

function blastn(query::String, subject::AbstractString, flags=[]; db::Bool=false)
    querypath = makefasta(query)
    if db
        return blastn(querypath, subject, flags, db=true)
    else
        return blastn(querypath, subject, flags)
    end
end

function blastn(query::Vector{String}, subject::Vector{String}, flags=[])
    querypath, subjectpath = makefasta(query), makefasta(subject)
    return blastn(querypath, subjectpath, flags)
end

function blastn(query::Vector{String}, subject::AbstractString, flags=[]; db::Bool=false)
    querypath = makefasta(query)
    if db
        return blastn(querypath, subject, flags, db=true)
    else
        return blastn(querypath, subject, flags)
    end
end

function blastn(query::AbstractString, subject::Vector{String}, flags=[])
    subjectpath = makefasta(subject)
    return blastn(query, subjectpath, flags)
end

"""
`blastp(query, subject, flags...)``
Runs blastn on `query` against `subject`.
    Subjects and queries may be file names (as strings), `BioSequence{AminoAcidSequence}` type or
    Array of `BioSequence{AminoAcidSequence}`.
    May include optional `flag`s such as `["-perc_identity", 95,]`. Do not use `-outfmt`.
"""
function blastp(query::AbstractPath, subject::AbstractPath, flags=[]; db::Bool=false)
    if db
        results = readblastXML(`blastp -query $query -db $subject $flags -outfmt 5`, seqtype = "prot")
    else
        results = readblastXML(`blastp -query $query -subject $subject $flags -outfmt 5`, seqtype = "prot")
    end
    return results
end

function blastp(query::String, subject::String, flags=[])
    querypath, subjectpath = makefasta(query), makefasta(subject)
    return blastp(querypath, subjectpath, flags)
end

function blastp(query::String, subject::Vector{String}, flags=[])
    querypath, subjectpath = makefasta(query), makefasta(subject)
    return blastp(querypath, subjectpath, flags)
end

function blastp(query::String, subject::AbstractString, flags=[]; db::Bool=false)
    querypath = makefasta(query)
    if db
        return blastp(querypath, subject, flags, db=true)
    else
        return blastp(querypath, subject, flags)
    end
end

function blastp(query::Vector{String}, subject::Vector{String}, flags=[])
    querypath, subjectpath = makefasta(query), makefasta(subject)
    return blastp(querypath, subjectpath, flags)
end

function blastp(query::Vector{String}, subject::AbstractString, flags=[]; db::Bool=false)
    querypath = makefasta(query)
    if db
        return blastp(querypath, subject, flags, db=true)
    else
        return blastp(querypath, subject, flags)
    end
end

function blastp(query::AbstractString, subject::Vector{String}, flags=[])
    subjectpath = makefasta(subject)
    return blastp(query, subjectpath, flags)
end

# Create temporary fasta-formated file for blasting.
function makefasta(sequence::String)
    path, io = mktemp()
    write(io, ">$path\n$sequence\n")
    close(io)
    return path |> Path
end

# Create temporary multi fasta-formated file for blasting.
function makefasta(sequences::Vector{T}) where T <: AbstractString
    path, io = mktemp()
    counter = 1
    for sequence in sequences
        write(io, ">$counter\n$sequence\n")
        counter += 1
    end
    close(io)
    return path |> Path
end
