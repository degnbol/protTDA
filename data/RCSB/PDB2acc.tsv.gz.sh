#!/usr/bin/env zsh
WORK=`git root`/data/alphafold/dl/RCSB/
# first line of each file is data_XXXX where XXXX is the PDB id.
# there is an entry _struct_ref.pdbx_db_accession which is followed by 
# whitespace, then the uniprot accession, a blank or the PDB id then a single 
# whitespace.
gunzip -cr $WORK/mmCIF | grep -E '^data_|^_struct_ref.pdbx_db_accession' | sed 's/data_/\nPDB /' > PDB2acc.tmp.tsv
mlr --x2t --from PDB2acc.tmp.tsv clean-whitespace + rename '_struct_ref.pdbx_db_accession,accession' +\
    filter '$accession != "" && $accession != $PDB' | gzip > PDB2acc.tsv.gz