#!/usr/bin/env zsh
mkdir -p PHCA/

TDA="`git root`/tools/hyperTDA"
for file in xyzCA/*.tsv; do
    OUT=PHCA/${file:r:t}.json
    if [ ! -f $OUT ]; then
        touch $OUT
        echo "Working on $OUT"
        date
        time julia --project=$TDA $TDA/src/xyz2PH.jl $file PHCA/ --H2 || return 1
        echo "Completed $OUT"
        date
    fi
done

my-job-stats -a -n -s
