#!/usr/bin/env zsh
for dir in PH/h5/{A..Z}{0..9}/; do
    >&2 echo $dir
    rmdir $dir
done
