#!/usr/bin/env zsh
part=$1
# tmux new -d './ripsererAF.jl '$part
for i in {1..`nproc`}; do
    tmux neww -d './ripsererAF.jl '$part
done

