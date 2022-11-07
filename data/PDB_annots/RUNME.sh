#!/usr/bin/env zsh
# to reproduce the data run this.
# Not necessary since the data is added to git.
cd $0:h
../CATH/RUNME.sh
../SCOPe/RUNME.sh
../ECOD/RUNME.sh
./PDB_annots.tsv.sh
