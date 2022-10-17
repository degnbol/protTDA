#!/usr/bin/env zsh
tmux new -d './ripsererAF.jl | tee -a ripsererAF.log'
for i in {1..`nproc`}; do
    tmux neww -d './ripsererAF.jl | tee -a ripsererAF.log'
done

