#!/usr/bin/env zsh
cd $0:h
mkdir -p xyzChain/

for file in xyz/*.tsv; do
    mlr -t split -g chain --prefix xyzChain/$file:r:t $file
done
