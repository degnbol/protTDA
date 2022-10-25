#!/usr/bin/env zsh
for i in {1..10}; do
    /usr/bin/time -ao rips.log -v ./ripsererAF.jl
done &>> ripsTime.log
