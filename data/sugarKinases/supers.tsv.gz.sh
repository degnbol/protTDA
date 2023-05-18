#!/usr/bin/env zsh
names_i=$(\ls cif/*.cif.gz | while read fname; do echo $fname:t:r:r; done | tr '\n' ' ')
cat <(\ls cif/*.cif.gz) <(\ls ../thermo/cif/*.cif.gz) |
    `git root`/src/pymol/super.sh supers.tsv.gz ${=names_i}

