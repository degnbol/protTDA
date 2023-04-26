#!/usr/bin/env zsh
\ls -f PH/h5 | while read fname; do
    if [ "$fname:e" = "h5" ]; then
        five=${fname[1,5]}
        if [ -s PH/hdf5/$five/$fname ]; then
            echo "rm PH/h5/$fname"
            rm PH/h5/$fname
        else
            echo "mv PH/h5/$fname PH/hdf5/$five/$fname"
            mkdir -p PH/hdf5/$five
            mv PH/h5/$fname PH/hdf5/$five/$fname
        fi
    fi
done
