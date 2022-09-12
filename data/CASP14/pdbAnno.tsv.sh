#!/usr/bin/env zsh
mlr --c2t --ifs semicolon --from raw/targets.csv put '$pdb = regextract_or_else($Description, " [0-9][a-z0-9]{3}", "")' + clean-whitespace > pdbAnno.tsv
