#!/usr/bin/env julia
using DataFrames
ROOT = readchomp(`git root`)

include("$ROOT/data/alphafold/acc2path_anno.jl")
df = annoAF("PDB2acc.tsv.gz")
unique!(df) # no change
dropmissing!(df) # reduction 134537 -> 116027. Lower than ~200k since not all PDBs have accession.

WORK = "$ROOT/data/alphafold/dl/RCSB"

# get copies of the PH for the accessions of interest.
for row in eachrow(df)
    pdb = lowercase(row.PDB)
    d1 = pdb[2:3]
    outdir = "$WORK/PHcmp/$d1"
    mkpath(outdir)
    cp("$ROOT/data/alphafold/"*row.path, "$outdir/$(row.accession)-AF.json.gz")
    cp("$WORK/PH/$d1/$pdb.json.gz", "$outdir/$(row.accession)-PDB_$pdb.json.gz")
end

