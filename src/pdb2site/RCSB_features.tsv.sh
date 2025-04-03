#!/usr/bin/env zsh
$0:h/RCSB_features.py RCSB/*.json.gz
pd-cat -N RCSB/*.tsv |
    mlr --tsv put '$PDB = sub(sub($Filename, ".*-", ""), "\.tsv", "")' +\
    cut -x -f Filename + uniq -a > RCSB_features.tsv
