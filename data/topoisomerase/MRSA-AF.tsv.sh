#!/usr/bin/env zsh
mlr -t --from topos-AF.tsv filter '$organism =~ "M.SA"' > MRSA-AF.tsv
mlr -t --from topos-AF.tsv filter '$name =~ "TOP[13][AB]?_HUMAN"' | sed 1d >> MRSA-AF.tsv
