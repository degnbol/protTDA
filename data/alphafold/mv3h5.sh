#!/usr/bin/env zsh
# for dir in PH/h5/{A..Z}{0..9}{A..Z}/; do
for dir in PH/h5/{A..Z}{0..9}{0..9}/; do
    >&2 echo $dir
    [ -d $dir ] || continue
    \ls -f $dir
done | grep '\.h5' | while read fname; do
    three=${fname[1,3]}
    five=${fname[1,5]}
    mkdir -p PH/hdf5/$five
    mv PH/h5/$three/$fname PH/hdf5/$five/$fname
done
