#!/usr/bin/env zsh
# to reproduce the data run this.
# Not necessary since the data is added to git.
# NOTE: ranges are seqid ranges, not residue ranges. So the values are relative 
# to the first residue of the chain, not the full sequence.
cd $0:h
../CATH/RUNME.sh
../SCOPe/RUNME.sh
../ECOD/RUNME.sh
./PDB_annots.tsv.sh
