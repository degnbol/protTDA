#!/usr/bin/env zsh
../../src/tsv2PH.jl ./mmCIF/*/*.tsv PH/

# remove other protein in complex
# https://www.rcsb.org/structure/4CHT
rm PH/4cht_B_1-Q9H9A7.h5
rm PH/5gve_B_1-Q9H7E2.h5
