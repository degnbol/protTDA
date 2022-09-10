#!/usr/bin/env zsh
TDA="`git root`/tools/hyperTDA"
for file in xyz/*; do
    OUT=PH/${file:r:t}.json
    if [ ! -f $OUT ]; then
        touch $OUT
        echo "Working on $OUT"
        date
        time julia --project=$TDA $TDA/src/xyz2PH.jl $file PH/
        echo "Completed $OUT"
        date
    fi
done

