#!/usr/bin/env zsh
# for dir in PH/h5/{A..Z}{0..9}{A..Z}/; do
for dir in PH/h5/{A..Z}{0..9}{0..9}/; do
    >&2 echo $dir
    [ -d $dir ] && rmdir $dir
done
