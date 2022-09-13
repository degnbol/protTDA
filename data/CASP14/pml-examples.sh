#!/usr/bin/env zsh
pymol pdb/6yj1.pdb `git root`/src/pml-color.py -- communitiesCA.json -k T1056 &
pymol pdb/6yj1.pdb `git root`/src/pml-color.py -- nodeCents/T1056.tsv -p blue_green &

# no ligand
pymol raw/T/T1099.pdb pdb/6ygh.pdb `git root`/src/pml-color.py -- communitiesCA.json &
pymol raw/T/T1099.pdb pdb/6ygh.pdb `git root`/src/pml-color.py -- nodeCents/T1099.tsv -p blue_green &

# antibody
pymol raw/T/T1036s1.pdb pdb/6vn1.pdb `git root`/src/pml-{color,dimother}.py -- communitiesCA.json &
pymol raw/T/T1036s1.pdb pdb/6vn1.pdb `git root`/src/pml-{color,dimother}.py -- communities.json H2 T1036s1 &

