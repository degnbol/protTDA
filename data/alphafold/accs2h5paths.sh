#!/usr/bin/env zsh

while read acc; do
    five=${acc[1,5]}
    echo "PH/hdf5/$five/$acc.h5"
done
