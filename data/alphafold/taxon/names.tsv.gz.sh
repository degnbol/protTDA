#!/usr/bin/env zsh
# downloaded from https://ftp.ncbi.nih.gov/pub/taxonomy/
sed 's/\t|\t/\t/g' taxdump/names.dmp | sed 's/\t|$//' |
    mlr -t --hi label tax,name,class,type + cut -x -f class +\
    filter '$name != "" && $type != ""' | gzip > names.tsv.gz
