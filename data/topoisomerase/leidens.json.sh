#!/usr/bin/env zsh
cd $0:h
`git root`/src/leiden.py PH/* > leidens.json
