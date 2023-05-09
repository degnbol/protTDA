#!/usr/bin/env zsh
mkdir -p taxon
wget https://ftp.ncbi.nih.gov/pub/taxonomy/taxcat.tar.gz
wget https://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz
tar -xzf taxcat.tar.gz -C taxon/ && rm taxcat.tar.gz
tar -xzf taxdump.tar.gz -C taxon/ && rm taxdump.tar.gz
