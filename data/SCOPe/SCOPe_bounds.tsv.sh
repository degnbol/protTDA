#!/usr/bin/env zsh
grep -E ':[0-9]+-[0-9]+' dir.des.scope.2.08-stable.txt | cut -f 3,4,5,6 | tr ' ' '\t' |
    table_unjag.sh 4 $'\t' , | tr ':' '\t' | awk 'NF == 5 {print}{}' |
    mlr -t --hi label SCOPe,domain,PDB,chain,range +\
    put '$range =~ "^(-?[0-9]+)-([0-9]+)$"; $start = "\1"; $stop = "\2";
    $domain = substr($domain, -1, -1)' +\
    cut -x -f range > SCOPe_bounds.tsv

