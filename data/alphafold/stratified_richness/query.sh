#!/usr/bin/env zsh
# Query postgres database for stratified richness analysis
# Outputs: size.tsv, disorder.tsv
cd "$(dirname "$0")"

{ print "domain\tsize_bin\tn_proteins\tavg_richness\tsd_richness"; psql -d protTDA -t -A -F $'\t' -f size.sql } > size.tsv
{ print "domain\tdisorder_bin\tn_proteins\tavg_richness\tsd_richness"; psql -d protTDA -t -A -F $'\t' -f disorder.sql } > disorder.tsv

echo "Output: size.tsv, disorder.tsv"
