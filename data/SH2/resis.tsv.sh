#!/usr/bin/env zsh
mlr -t --hi filter '$1 =~ "^ATOM"' +\
    put '$resi = substr1($1, 23, 26); $PDB = regextract(FILENAME, "[0-9][0-9A-Za-z]{3}")' +\
    cut -x -f 1 + uniq -a + clean-whitespace pdb/*.pdb.gz > resis.tsv

# annotate min and max resi number of each PDB
mlr -I -t --from resis.tsv stats1 -a min,max,count -f resi -g PDB + join -j PDB -f resis.tsv

