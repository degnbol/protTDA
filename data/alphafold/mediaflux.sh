#!/usr/bin/env zsh
# USE (from tmux): ./mediaflux.sh
for i in {1..999}; do
    dir=`./mediaflux_next.sh`
    [ -n "$dir" ] || return 0
    mkdir -p PH/MF/$dir
    for d1 in PH/$dir/*/; do
        echo $d1
        TAR=PH/MF/$dir/${d1:t}.tar
        tar cf $TAR $d1
        # `git root`/mediaflux/upload.sh $TAR PH/$dir/
    done
done
