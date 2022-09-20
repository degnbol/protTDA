#!/usr/bin/env zsh
cut -d' ' -f4- GASS-METAL/templates_lit.txt | sed -E 's/([A-Z0-9]+ [A-Z0-9]+ [A-Z0-9]+) /\1;/g' | paste <(cut -d' ' -f-3 GASS-METAL/templates_lit.txt) - |
    `git root`/src/table_unjag.sh 2 $'\t' ';' | tr ' ' '\t' | mlr -t --hi label PDB,EC,metal,resn,resi,chain > metal_sites.tsv
