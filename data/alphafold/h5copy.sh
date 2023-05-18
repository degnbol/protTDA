#!/usr/bin/env zsh
\ls -fA PH/hdf5 | shuf | while read indir; do
    outfname="PH/h5/$indir.h5"
    [ -f $outfname ] && continue
    [ -f $outfname.inprogress ] && continue
    touch $outfname.inprogress
    echo $indir
    \ls -fA PH/hdf5/$indir | while read fname; do
        h5copy -i PH/hdf5/$indir/$fname -o $outfname.inprogress -s '/' -d $fname:r
    done
    mv $outfname{.inprogress,}
done
