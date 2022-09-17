#!/usr/bin/env zsh
export PATH="`git root`/src:$PATH"

mkdir -p pdb

mlr -t --from SH2prots.tsv cut -f PDB | tr ';' '\n' |
    sed 1d | sed '/^$/d' | sort -u | while read id; do
        [ -f pdb/$id.pdb.gz ] || wget -P pdb/ https://files.rcsb.org/download/$id.pdb.gz
    done

