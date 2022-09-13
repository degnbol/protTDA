#!/usr/bin/env zsh
mkdir -p $0:h/pdb
cd $0:h/pdb

mlr -t --from ../pdbAnno.tsv uniq -f pdb | sed 1d | sed '/^$/d' | while read id; do
    wget https://files.rcsb.org/download/$id.pdb.gz
done
