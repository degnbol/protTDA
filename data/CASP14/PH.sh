#!/usr/bin/env zsh
mkdir -p PH/

TDA="`git root`/tools/hyperTDA"
for file in xyz/*.tsv; do
    OUT=PH/${file:r:t}.json
    if [ ! -f $OUT ]; then
        touch $OUT
        echo "Working on $OUT"
        date
        time julia --project=$TDA $TDA/src/xyz2PH.jl $file PH/ --H2 || return 1
        echo "Completed $OUT"
        date
    fi
done

my-job-stats -a -n -s
