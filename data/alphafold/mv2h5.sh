#!/usr/bin/env zsh
for dir in PH/h5/{A..Z}{0..9}/; do
    >&2 echo $dir
    \ls -f $dir
done | grep '\.h5' | while read fname; do
    two=${fname[1,2]}
    five=${fname[1,5]}
    mkdir -p PH/hdf5/$five
    if [ -s "PH/hdf5/$five/$fname" ]; then
        rm PH/h5/$two/$fname
    else
        mv PH/h5/$two/$fname PH/hdf5/$five/$fname
    fi
done
