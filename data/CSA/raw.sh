#!/usr/bin/env zsh
# raw data listed at https://www.ebi.ac.uk/thornton-srv/m-csa/download/
cd $0:h
mkdir -p raw/

# copy-pasted descriptions:

# This file lists all the residues, cofactors, reactants and products for all the 
# entries in M-CSA. Reference UniProt and PDB IDs are given, as well as the 
# reference reaction EC number. Residues are identified by their chain and 
# residue ID in the biological assembly of the reference PDB. Cofactors are 
# identified by their name, HET code, KEGG compound ID, and ChEBI ID. Reactants 
# and products are identified by their KEGG compound ID and ChEBI ID. Roles are 
# grouped in three categories: reactant, interaction, and spectator. The parent 
# role is given when available, it is derived from the EMO (Enzyme Mechanism 
# Ontology)

wget -P raw/ https://www.ebi.ac.uk/thornton-srv/m-csa/media/flat_files/curated_data.csv

# 'CSA Style' files with list of curated catalytic residues
# Curated catalytic residues
# Each line of this file corresponds to a catalytic residue in the M-CSA. Only 
# catalytic residues manually annotated in the reference PDB are included. This 
# file matches the style of the flat file provided by the CSA v2.0 website. Resid 
# and chain names are the ones found in the first biological assembly defined by 
# PDBe, which is available as a cif file for each PDB entry. Function location 
# corresponds to the portion of the residue important for catalysis: S - side 
# chain; N - main chain amide or main chain N-terminus; C - main chain carbonyl 
# or main chain C-terminus; U - post translation modification; M - main chain.
wget -P raw/ https://www.ebi.ac.uk/thornton-srv/m-csa/media/flat_files/literature_pdb_residues.csv

# Curated catalytic residues with their roles annotated
# Each line of this file corresponds to a role done by a catalytic residue. If 
# a catalytic residue has more than one role, it appears on more than one line. 
# The roles are grouped in three categories: reactant, interaction, and 
# spectator. The parent role is given when available, it is derived from the 
# EMO (Enzyme Mechanism Ontology)
wget -P raw/ https://www.ebi.ac.uk/thornton-srv/m-csa/media/flat_files/literature_pdb_residues_roles.csv

