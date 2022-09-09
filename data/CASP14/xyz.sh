#!/usr/bin/env zsh
export PATH="`git root`/src:$PATH"
cd $0:h

mkdir -p xyz

for file in raw/*/*.pdb; do
    pdb2xyzBackbone.sh < $file > xyz/${file:r:t}.tsv
done

