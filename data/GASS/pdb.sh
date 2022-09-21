#!/usr/bin/env zsh
cd $0:h
mkdir -p pdb/
infile=metal_sites.tsv
mlr -t uniq -f 'PDB' $infile | sed 1d | while read id; do
    [ -f pdb/$id.pdb.gz ] || wget -P pdb/ https://files.rcsb.org/download/$id.pdb.gz
done

