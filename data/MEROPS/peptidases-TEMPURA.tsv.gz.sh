#!/usr/bin/env zsh
anno_cols=Topt_ave,Tmin,Tmax,assembly_or_accession,genus_and_species,strain,superkingdom
mlr -t --from peptidases.tsv.gz join -i csv -f ../TEMPURA/200617_TEMPURA.csv.gz -j taxonomy -l taxonomy_id -r organism --lk $anno_cols |
    gzip > peptidases-TEMPURA.tsv.gz
