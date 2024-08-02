#!/usr/bin/env zsh
mlr -t --from topos-AF.tsv filter '$organism =~ "M.SA"' > MRSA-AF.tsv
mlr -t --from topos-AF.tsv filter '$name =~ "TOP[13][AB]?_HUMAN"' | sed 1d >> MRSA-AF.tsv
# specfically requested by Emma Tomlinson via email
mlr -t --from topos-AF.tsv filter '$pdb =~ "4R1F;" || $pdb =~ "7QFN;" || $pdb =~ "7YQ8;" || $pdb =~ "6ZY6;"' | sed 1d >> MRSA-AF.tsv
