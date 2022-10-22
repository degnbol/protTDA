#!/usr/bin/env zsh
for i in {1..10}; do
    time -l ./ripsererAF.jl &>> rips.log
done
