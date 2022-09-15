#!/usr/bin/env zsh
cd $0:h
mlr --c2t --from raw/literature_pdb_residues.csv rename 'PDB ID,RCSB,CHAIN ID,chain,RESIDUE NUMBER,resi' + uniq -f resi,RCSB,chain > CSA_sites.tsv
