#!/usr/bin/env zsh
# Unpack archives

# run from anywhere
cd $0:h

for file in *.tar.gz; do
    tar -xf $file
done

for file in communities*.gz; do
    gunzip $file
done

