#!/usr/bin/env zsh
tmux new -d './ripsererAF.jl'
for i in {1..63}; do
    tmux neww -d './ripsererAF.jl'
done

