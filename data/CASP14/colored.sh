#!/usr/bin/env zsh
mkdir -p colored
mlr -t --from pdbAnno.tsv cut -f Target,pdb + filter '$pdb != ""' |
    while read Target pdb; do
        pymol -c raw/pdb/$Target.pdb pdb/$pdb.pdb pml-color.py
    done

