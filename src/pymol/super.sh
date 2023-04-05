#!/usr/bin/env zsh
# Write output of pymol super command to stdout
# NOTE: that there is a difference between .py and .pml, pymol will load the latter as commands.
# https://pymolwiki.org/index.php/Super
# output format: (https://pymolwiki.org/index.php/Align)
# 1. RMSD after refinement
# 2. Number of aligned atoms after refinement
# 3. Number of refinement cycles
# 4. RMSD before refinement
# 5. Number of aligned atoms before refinement
# 6. Raw alignment score
# 7. Number of residues aligned
# REQ: pymol
# USE: \ls INDIR/*.cif.gz | src/super.sh OUTFILE.tsv.gz
# WHERE optional i (0-indexed) means the ith entry is compared to the rest, 
# otherwise all-vs-all.
INFILES=`cat -`
pymol -qQc ${=INFILES} $0:h/super.py -- $@
