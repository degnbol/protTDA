#!/usr/bin/env zsh
gunzip -cr PH/ | mlr --ijson --ho cut -f n | sed '/^$/d' | gzip > lengths.txt.gz
