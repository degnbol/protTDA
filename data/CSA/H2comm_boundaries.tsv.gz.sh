#!/usr/bin/env zsh
# Boundaries.csv from Agnese over whatsapp
# mlr --c2t --from Boundaries.csv rename 'res,resi,index of CA,indexCA,Protein,RCSB,Chain,chain' + put '$resi = int($resi)' | gzip > H2comm_boundaries.tsv.gz
# mlr --c2t --from Boundaries_catalytic.csv rename 'Boundary index,index,Boundary residue,resi,PDB ID,RCSB,Chain,chain' + put '$resi = int($resi)' > H2comm_boundaries.tsv
mlr --c2t --from Insides_catalitic.csv rename 'Inside index,index,Inside residue,resi,PDB ID,RCSB,Chain,chain' + put '$resi = int($resi)' > H2comm_boundaries.tsv
