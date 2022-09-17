#!/usr/bin/env zsh
# unjag PDB column, then filter domains x PDB entries by seeing if resi from 
# domain ends are contained in the PDB.
`git root`/src/table_unjag.sh 8 $'\t' ';' < SH2prots.tsv |
    mlr -t filter '$PDB != ""' +\
    join -j PDB,domainStart -l PDB,resi -f resis.tsv +\
    join -j PDB,domainStop -l PDB,resi -f resis.tsv +\
    put '$domainFrac = ($domainStop - $domainStart) / ($resi_max - $resi_min)' +\
    reorder -f PDB,resi_min,resi_max,domainStart,domainStop,domainFrac > SH2PDBs.tsv
