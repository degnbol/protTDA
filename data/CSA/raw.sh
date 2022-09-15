#!/usr/bin/env zsh
cd $0:h
mkdir -p raw/
wget -P raw/ https://www.ebi.ac.uk/thornton-srv/m-csa/media/flat_files/curated_data.csv
wget -P raw/ https://www.ebi.ac.uk/thornton-srv/m-csa/media/flat_files/literature_pdb_residues.csv
wget -P raw/ https://www.ebi.ac.uk/thornton-srv/m-csa/media/flat_files/literature_pdb_residues_roles.csv
