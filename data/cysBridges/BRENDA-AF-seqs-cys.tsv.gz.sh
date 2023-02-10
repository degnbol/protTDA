#!/usr/bin/env zsh
mlr -t --from ../BRENDA/tempRanges-AF.tsv filter '$path != ""' +\
    join -j accession -f BRENDA-AF-seqs.tsv.gz |
    julia -t 32 ./cysBridges.jl > BRENDA-AF-seqs-cys.tsv.gz
