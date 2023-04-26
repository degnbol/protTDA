#!/usr/bin/env zsh
for i_proc in {1..10}; do
    tmux neww 'zsh'
    tmux send-keys 'for retries in {1..100}; do ./json2hdf5.jl; done' ENTER
done
