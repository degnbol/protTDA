#!/usr/bin/env zsh
mlr -t --from ../MEROPS/peptidases-TEMPURA-AF.tsv.gz filter '$path != "NA"' +\
    join -j accession -f peptidases-TEMPURA-AF-seqs.tsv.gz |
    julia -t 32 ./cysBridges.jl > peptidases-TEMPURA-AF-seqs-cys.tsv.gz
