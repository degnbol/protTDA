#!/usr/bin/env zsh
table_unjag.sh 2 $'\t' , < cath-domain-boundaries-seqreschopping.txt |
    mlr -t --hi label raw,range +\
    put -f CATH_bounds.tsv.mlr + cut -x -f raw,range > CATH_bounds.tsv
