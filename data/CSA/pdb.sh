#!/usr/bin/env zsh
cd $0:h
mkdir -p pdb/
infile=raw/literature_pdb_residues.csv 
mlr -c uniq -f 'PDB ID' $infile | sed 1d | while read id; do
    [ -f pdb/$id.pdb.gz ] || wget -P pdb/ https://files.rcsb.org/download/$id.pdb.gz
done

