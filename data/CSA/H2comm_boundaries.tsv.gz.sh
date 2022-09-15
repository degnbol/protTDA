#!/usr/bin/env zsh
# Boundaries.csv from Agnese over whatsapp
mlr --c2t --from Boundaries.csv rename 'res,resi,index of CA,indexCA,Protein,RCSB,Chain,chain' + put '$resi = int($resi)' | gzip > H2comm_boundaries.tsv.gz
