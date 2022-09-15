#!/usr/bin/env zsh
export PATH="`git root`/src:$PATH"
cd $0:h

mkdir -p xyz

for file in pdb/*.pdb.gz; do
    gunzip -c $file | pdb2xyzCA.sh > xyz/${file:r:r:t}.tsv
done

