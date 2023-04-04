#!/usr/bin/env zsh
mlr -t --from bork1992_table1.tsv fill-down --all |
    `git root`/src/table_unjag.sh 6 "\t" ', ' > bork1992_table1-unjag.tsv
