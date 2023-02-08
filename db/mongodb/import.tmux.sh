#!/usr/bin/env zsh
ROOT=`git root`
tmux new -n import -d
d0=$ROOT/data/alphafold/PH
\ls $d0 | head -n 60 | while read d1base; do
    tmux neww
    tmux send-keys "./import.jl $d0/$d1base" Enter
done


