#!/usr/bin/env zsh
conda activate protTDA 2> /dev/null
export ROOT=$0:h
export PATH="$PATH:/usr/lib64/openmpi/bin"
# for cargo build in rust project (data/alphafold)
export HDF5_DIR=$ROOT/bin/HDF5-1_12_0
