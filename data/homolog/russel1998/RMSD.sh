#!/usr/bin/env zsh
pymol -cq cifs/$1.cif cifs/$3.cif -d "super $1 and chain $2, $3 and chain $4" |
    grep 'RMSD =' | sed 's/.*= *//' | grep -o '^[0-9.]\+'
