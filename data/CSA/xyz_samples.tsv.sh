#!/usr/bin/env zsh
mlr -t put '$file = FILENAME' + uniq -cf file + sort -n count + decimate -bn 25 xyz/*.tsv > xyz_samples.tsv
