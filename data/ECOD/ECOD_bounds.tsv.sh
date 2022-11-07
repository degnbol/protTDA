#!/usr/bin/env zsh
sed '1,4d' ecod.latest.domains.txt | sed '1s/^#//' |
    mlr -t cut -f ecod_domain_id,manual_rep,f_id,pdb,chain,seqid_range +\
    put '$manual = $manual_rep == "MANUAL_REP" ? 1 : 0;
    $domain = substr($ecod_domain_id, -1, -1)' +\
    rename 'pdb,PDB,f_id,ECOD' | table_unjag.sh 6 $'\t' , |
    mlr -t put '$seqid_range =~ "^(.):(-?[0-9]+)-(-?[0-9]+)$";
    $chain = "\1"; $start = "\2"; $stop = "\3"' +\
    cut -x -f ecod_domain_id,manual_rep,seqid_range > ECOD_bounds.tsv
