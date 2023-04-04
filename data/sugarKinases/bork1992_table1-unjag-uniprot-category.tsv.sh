#!/usr/bin/env zsh
# all are reviewed, all EC numbers match
mlr -t --from bork1992_table1-unjag.tsv put '$Uniprot = sub($Uniprot, "/", "_")' + join -f bork1992_table1-unjag-uniprot.tsv -j Uniprot -r Uniprot -l From + cut -x -f 'Entry Name,Reviewed,EC number' > bork1992_table1-unjag-uniprot-category.tsv
