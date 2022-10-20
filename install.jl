#!/usr/bin/env julia
using Pkg
Pkg.activate(".")
Pkg.add(["SparseArrays", "LinearAlgebra",
         "JSON", "GZip", "TarIterators", "TranscodingStreams", "CodecZlib", "BoundedStreams",
         "Ripserer"])

