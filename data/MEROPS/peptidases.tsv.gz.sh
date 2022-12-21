#!/usr/bin/env zsh
sed 's/:\t/:/' dnld_list.txt | sed 's/:/\t/' |
    mlr -t label database,accession,subfamily,organism +\
    put '$superfamily = substr($subfamily, 0, 0)' +\
    join -f peptidase_superfamilies.tsv -j superfamily +\
    cut -x -f superfamily,database +\
    uniq -a | gzip -c > peptidases.tsv.gz
