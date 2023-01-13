#!/usr/bin/env zsh
WORK=../alphafold/dl/RCSB
gunzip -cr $WORK/PH/ | mlr --ijson --ho cut -f n | sed '/^$/d' | gzip > lengths.txt.gz
