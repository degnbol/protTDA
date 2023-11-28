#!/usr/bin/env zsh
# hdf5 source code downloaded from website
# https://www.hdfgroup.org/downloads/hdf5/source-code/
# transferred from local with scp
cd hdf5-*/
# based on release_docs/INSTALL_parallel and finding mpicc with rpm -ql openmpi after trying mpich
CC=/usr/lib64/openmpi/bin/mpicc ./configure --enable-parallel --prefix=$(realpath ../HDF5)
make
make check
make install
