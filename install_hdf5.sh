#!/usr/bin/env zsh
# https://juliaio.github.io/HDF5.jl/stable/#Using-custom-or-system-provided-HDF5-binaries

julia <<EOF
using MPIPreferences
# libmpi path found with rpm -ql openmpi (aliased with yumwhere)
MPIPreferences.use_system_binary(; library_names=["/usr/lib64/openmpi/lib/libmpi.so"])
EOF

julia <<EOF
ROOT = `git root` |> readchomp
ENV["JULIA_HDF5_PATH"] = ROOT * "/bin/HDF5"
Pkg.build("HDF5")
# check if worked
# https://juliaio.github.io/HDF5.jl/stable/mpi/
using MPI
using HDF5
@assert HDF5.has_parallel()
EOF

# for rust
mamba install hdf5=1.12.0
# then before `cargo build`, call:
export HDF5_DIR=`git root`/bin/mambaforge

