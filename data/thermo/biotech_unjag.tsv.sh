#!/usr/bin/env zsh
`git root`/src/table_unjag.sh 2 "\t" ', ' < biotech.tsv | grep -v 'Non characterised thermophiles' | mlr -t put '$Thermophile = sub($Thermophile, " and .*", "")' > biotech_unjag.tsv
