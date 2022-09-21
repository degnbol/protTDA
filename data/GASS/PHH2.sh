#!/usr/bin/env zsh
mkdir -p PHH2
TDA="`git root`/tools/hyperTDA"
julia -t 64 --project=$TDA $TDA/src/xyz2PH.jl xyz/ PHH2/ --H2

