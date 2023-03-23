#!/usr/bin/env zsh
# https://juliaio.github.io/HDF5.jl/stable/#Using-custom-or-system-provided-HDF5-binaries

julia <<EOF
#!/usr/bin/env julia
using Pkg
Pkg.add(["MPI", "MPIPreferences"])
using MPIPreferences
# libmpi path found with rpm -ql openmpi (aliased with yumwhere)
MPIPreferences.use_system_binary(; library_names=["/usr/lib64/openmpi/lib/libmpi.so"])
EOF

julia <<EOF
#!/usr/bin/env julia
ROOT = `git root` |> readchomp
ENV["JULIA_HDF5_PATH"] = "$ROOT/bin/HDF5"
using Pkg
Pkg.add("HDF5")
Pkg.build("HDF5")
# check if worked
# https://juliaio.github.io/HDF5.jl/stable/mpi/
using MPI
using HDF5
@assert HDF5.has_parallel()
EOF

