#!/usr/bin/env zsh
pymol pdb/6yj1.pdb `git root`/src/pml-color.py -- communitiesCA.json -k T1056 &
pymol pdb/6yj1.pdb `git root`/src/pml-color.py -- nodeCents/T1056.tsv -p blue_green &

# no ligand
pymol raw/*/T1099.pdb pdb/6ygh.pdb `git root`/src/pml-color.py -- communitiesCA.json &
pymol raw/*/T1099.pdb pdb/6ygh.pdb `git root`/src/pml-color.py -- nodeCents/T1099.tsv -p blue_green &

# antibody
pymol raw/*/T1036s1.pdb pdb/6vn1.pdb `git root`/src/pml-{color,cmpother}.py -- communitiesCA.json &
pymol raw/*/T1036s1.pdb pdb/6vn1.pdb `git root`/src/pml-{color,cmpother}.py -- communities.json -k H2 T1036s1 &
pymol raw/*/T1036s1.pdb pdb/6vn1.pdb `git root`/src/pml-{color,cmpother}.py -- nodeCentsH2/T1036s1.tsv &

pymol raw/*/T1032.pdb pdb/6n64.pdb `git root`/src/pml-{color,cmpother}.py -- communities.json -k H2 T1032 &
pymol raw/*/T1030.pdb pdb/6poo.pdb `git root`/src/pml-{color,cmpother}.py -- communities.json -k H2 T1030 &

