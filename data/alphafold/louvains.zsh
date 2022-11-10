#!/usr/bin/env zsh
for i in {1..10}; do
    /usr/bin/time -ao louvain.log -v ./louvains.jl
done &>> lovainTime.log
