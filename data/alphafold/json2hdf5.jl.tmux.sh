#!/usr/bin/env zsh
for indir in PH/*; do
    [ $indir = "PH/100" ] || [ $indir = "PH/h5" ] || [ $indir = "PH/neo4j" ] || {
        [ "${indir[1,4]}" = "PH/1" ] && tmux neww -d "./json2hdf5.jl $indir"
    }
done
