#!/usr/bin/env zsh
cd $0:h
`git root`/src/leiden.py PH/* HDF5/* | gzip > leidens.json
