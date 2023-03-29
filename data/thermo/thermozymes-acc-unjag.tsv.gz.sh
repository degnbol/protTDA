#!/usr/bin/env zsh
mlr -t --from thermozymes-acc.tsv.gz cut -rf 'Entry$,EC,Tax' + rename -r 'Entry,acc,EC.*,EC,Tax.*,taxonLin' |
    `git root`/src/table_unjag.sh 2 "\t" '; ' | gzip > thermozymes-acc-unjag.tsv.gz
