#!/usr/bin/env zsh
mlr -t --from ../MEROPS/peptidases-TEMPURA-AF.tsv.gz uniq -f accession |
    sed 1d | `git root`/src/fetchseqs.py | gzip > peptidases-TEMPURA-AF-seqs.tsv.gz
