#!/usr/bin/env zsh
mkdir -p cifs/
cat pdbs.txt | xargs -I {} wget -P cifs/ 'https://files.rcsb.org/download/'{}'.cif.gz'

