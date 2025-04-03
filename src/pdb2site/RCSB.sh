#!/usr/bin/env zsh
# EXAMPLE: mlr uniq -f pdb INFILE.tsv | sed 1d | RCSB.sh
$0:h/RCSB_rest.sh uniprot PDBs.txt 1 RCSB/
$0:h/RCSB_rest.sh polymer_entity_instance PDBs.txt A RCSB/
# delete empty files created when no result was returned for a PDB id.
find RCSB/ -size 0 -delete
# save space
# gzip RCSB/*.json
