#!/usr/bin/env zsh
export PATH="`git root`/src:$PATH"
cd $0:h

mkdir -p xyzCA

for file in raw/*/*.pdb; do
    pdb2xyzCA.sh < $file > xyzCA/${file:r:t}.tsv
done

