#!/usr/bin/env julia
# Stream tar file
using TarIterators, TranscodingStreams, CodecZlib
using BoundedStreams
# isopen is not defined for BoundedInputStream but it will always be open when 
# given to TranscodingStream
TranscodingStreams.isopen(::BoundedInputStream{IOStream}) = true

"""
Iterate through gzipped files within a tar.
Iterator elements are (path, stream) where io is decompressed.
"""
function targzip(io)
    ((h.path, TranscodingStream(GzipDecompressor(), _io)) for (h, _io) in TarIterator(io))
end
function targzip(io, predicate)
    ((h.path, TranscodingStream(GzipDecompressor(), _io)) for (h, _io) in TarIterator(io, predicate))
end

