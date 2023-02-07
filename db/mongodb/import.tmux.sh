#!/usr/bin/env zsh
ROOT=`git root`
tmux new -n import
d0=$ROOT/data/alphafold/PH
\ls $d0 | head -n 150 | while read d1base; do
    tmux neww "./import.jl $d0/$d1base"
done


