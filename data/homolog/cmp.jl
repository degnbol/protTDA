#!/usr/bin/env julia
using HDF5
using Clustering
using BioSequences, BioTools.BLAST
using Glob: glob
using DelimitedFiles

noext(path) = splitext(path)[1]

accs = readdlm("ProteinPathTracker.tsv")[:, 2] .|> String

paths = glob("testfiles/*.h5")
fnames = basename.(paths) .|> noext
fhs = paths .|> h5open

fhs = zip(fnames, fhs) |> Dict

groups = HDF5.Group[]
for acc in accs
    try push!(groups, fhs[acc[1:end-1]][acc])
    catch KeyError;
    end
end

AAs = [attrs(g)["AA"] for g in groups] .|> AminoAcidSequence
cent1s = [g["Cas"][:, 5] for g in groups]
cent2s = [g["Cas"][:, 6] for g in groups]

fhs |> values .|> close

blast = blastp(AAs[end], AAs[1:end-1])[1]


