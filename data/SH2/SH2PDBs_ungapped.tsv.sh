#!/usr/bin/env zsh
mlr -t --from resis.tsv join -j PDB -f SH2PDBs.tsv --lk domainStart,domainStop + filter '$domainStart <= $resi && $resi <= $domainStop' +\
    uniq -c -f PDB,domainStart,domainStop + put '$domainSpan = $domainStop - $domainStart + 1' + filter '$domainSpan == $count' +\
    cut -f PDB,domainStart,domainStop + join -j PDB,domainStart,domainStop -f SH2PDBs.tsv + sort -nr domainFrac > SH2PDBs_ungapped.tsv
