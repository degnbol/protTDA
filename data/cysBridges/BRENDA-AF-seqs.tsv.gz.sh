#!/usr/bin/env zsh
mlr -t --from ../BRENDA/tempRanges-AF.tsv uniq -f accession |
    sed 1d | `git root`/src/fetchseqs.py | mlr -t label accession,AA |
    gzip > BRENDA-AF-seqs.tsv.gz
