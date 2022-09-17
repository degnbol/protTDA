#!/usr/bin/env zsh
# unjag PDB column, then filter domains x PDB entries by seeing if resi from 
# domain ends are contained in the PDB.
`git root`/src/table_unjag.sh 8 $'\t' ';' < SH2prots.tsv |
    mlr -t filter '$PDB != ""' +\
    join -j PDB,domainStart -l PDB,resi -f resis.tsv +\
    join -j PDB,domainStop -l PDB,resi -f resis.tsv +\
    put '$resi_span = $resi_max - $resi_min + 1; $domainFrac = ($domainStop - $domainStart + 1) / ($resi_count)' +\
    reorder -f PDB,resi_min,resi_max,resi_span,resi_count,domainStart,domainStop,domainFrac +\
    sort -nr domainFrac > SH2PDBs.tsv
