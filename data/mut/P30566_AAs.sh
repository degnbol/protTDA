#!/usr/bin/env zsh
cd $0:h

# uniprot accession found by finding the single human entry for Adenylosuccinate lyase.

echo "Neutral"
mlr --c2t --from mutations.csv.gz filter '$ID == "P30566" && $Label == "Neutral and Structurally Neutral"' + uniq -f AA | sed 1d | sort -n
echo "Damaging"
mlr --c2t --from mutations.csv.gz filter '$ID == "P30566" && $Label == "Damaging and Structurally Damaging"' + uniq -f AA | sed 1d | sort -n

