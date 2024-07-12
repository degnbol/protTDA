#!/usr/bin/env zsh
mkdir -p mmCIF/
cd mmCIF/

mlr -t --from ../MRSA-AF.tsv cut -f pdb + put '$pdb = tolower($pdb)' | sed 1d | tr ';' '\n' | grep -v '^$' | while read PDB; do
    TWO=$PDB[2,3]
    mkdir -p $TWO
    wget -O $TWO/${PDB}.cif.gz https://files.wwpdb.org/pub/pdb/data/structures/divided/mmCIF/$TWO/${PDB}.cif.gz
done

../RCSB/ripsererAF.jl
# remove other protein in complex
# https://www.rcsb.org/structure/4CHT
rm PH/ch/4cht_B_1-Q9H9A7.json.gz
rm PH/gv/5gve_B_1-Q9H7E2.json.gz
rmdir PH/*/
