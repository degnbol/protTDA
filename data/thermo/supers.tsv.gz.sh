#!/usr/bin/env zsh
\ls cif/*.cif.gz | `git root`/src/pymol/super.sh supers.tsv.gz

