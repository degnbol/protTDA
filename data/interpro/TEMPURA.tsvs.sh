#!/usr/bin/env zsh
for file in *.tsv; do echo $file; ./anno_TEMPURA.sh $file > ${file:r}-TEMPURA.tsv; done
