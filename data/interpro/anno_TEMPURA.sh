#!/usr/bin/env zsh
# USE: ./anno_TEMPURA.sh INTERPRO.tsv
labels=accession,reviewed,name,taxonomy_id,scientificName,length,interpro,location,empty
anno_cols=Topt_ave,Tmin,Tmax,assembly_or_accession,genus_and_species,strain,superkingdom
mlr -t label $labels + cut -x -f empty + \
    join -i csv -f ../TEMPURA/200617_TEMPURA.csv.gz -j taxonomy_id --lk $anno_cols \
    $1
