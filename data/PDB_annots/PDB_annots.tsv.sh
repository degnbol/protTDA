#!/usr/bin/env zsh
mlr -t --from ../CATH/CATH_bounds.tsv put '$DB = "CATH"' > cath.tmp
mlr -t --from ../SCOPe/SCOPe_bounds.tsv rename SCOPe,hier + put '$DB = "SCOPe"' > scope.tmp
mlr -t --from ../ECOD/ECOD_bounds.tsv rename ECOD,hier + put '$DB = "ECOD"' > ecod.tmp
mlr -t unsparsify *.tmp | gzip > PDB_annots.tsv.gz
rm *.tmp
