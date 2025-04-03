#!/usr/bin/env zsh
export PATH="`git root`/src:$PATH"
cd $0:h

mkdir -p xyztsv

for file in raw/*/*.pdb; do
    pdb2tsv.sh < $file > xyztsv/${file:r:t}.tsv
done

