#!/usr/bin/env zsh
# Get data for a PDB id using the RCSB REST
# https://data.rcsb.org/
# https://data.rcsb.org/redoc/index.html
# REQUIRES: jq installed for json formatting, e.g. brew install jq
# USE: ./RCSB_rest.sh SERVICE PDB CHAIN/ENTITY [OUT]
# - SERVICE: uniprot, polymer_entity, polymer_entity_instance, etc.
# - PDB: aka. entry e.g. 3O1Z, or a file with an entry on each line
# - CHAIN/ENTITY: if unsure, use A or 1.
# - OUT: output file for single pdb or directory for multiple, where each are named SERVICE-PDB.json. 
#        Can also be - for stdout.
service=$1
pdb=$2
chain_entity=$3
out=$4

if [ -f "$pdb" ]; then
    if [ "$out" = "-" ]; then
        outfile="-"
    else
        mkdir -p $out/
    fi
    cat $pdb | while read pdb; do
        [ "$out" = "-" ] || outfile=$out/$service-$pdb.json 
        wget -O - https://data.rcsb.org/rest/v1/core/$service/$pdb/$chain_entity | jq > $outfile
    done
else
    wget -O - https://data.rcsb.org/rest/v1/core/$service/$pdb/$chain_entity | jq > $out
fi
