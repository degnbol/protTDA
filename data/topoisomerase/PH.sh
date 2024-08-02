#!/usr/bin/env zsh
../RCSB/ripsererAF.jl
# remove other protein in complex
# https://www.rcsb.org/structure/4CHT
rm PH/ch/4cht_B_1-Q9H9A7.json.gz
rm PH/gv/5gve_B_1-Q9H7E2.json.gz
# rm empty failed dirs
rmdir PH/*/
