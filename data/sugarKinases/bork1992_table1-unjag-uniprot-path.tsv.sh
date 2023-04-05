#!/usr/bin/env zsh
mlr -t --from bork1992_table1-unjag-uniprot.tsv uniq -f Entry | sed 1d |
    ../alphafold/accs2paths.jl > bork1992_table1-unjag-uniprot-path.tsv
