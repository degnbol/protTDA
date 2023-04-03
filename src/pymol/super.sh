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
# USE: src/super.sh FILE1 FILE2 ... >> OUTFILE.tsv
pymol -qQc ${=@} $0:h/super.py
