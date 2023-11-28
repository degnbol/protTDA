#!/usr/bin/env julia
using Pkg
Pkg.activate(".")
Pkg.add([
"DataFrames", "CSVFiles", "Glob", "StatsBase",
"SparseArrays", "LinearAlgebra", "Distances",
"JSON", "GZip", "TarIterators", "TranscodingStreams", "CodecZlib", "BoundedStreams",
"Ripserer",
"HDF5", "H5Zzstd", "MPI", "MPIPreferences",
"Arrow", "CodecLz4",
"CrystalInfoFramework",
"Plots",
])

