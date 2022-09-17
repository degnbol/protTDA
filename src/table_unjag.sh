#!/usr/bin/env zsh
# unjag a single column from a table.
# example unjagging column 3 with delimiter tab and secondary delimiter semicolon:
# table_unjag.sh 3 $'\t' ';' < infile.tsv > outfile.tsv
awk -F$2 'BEGIN{OFS="'$2'"}{n=split($'$1', a, "'$3'"); for (i=1; i<=n; i++) {$'$1' = a[i]; print}}'
