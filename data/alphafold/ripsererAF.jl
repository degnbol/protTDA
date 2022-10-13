#!/usr/bin/env julia
using PyCall
@pyinclude "fetch.py"
using Ripserer
using JSON
using GZip
# https://www.lucidchart.com/techblog/2019/12/06/json-compression-alternative-binary-formats-and-compression-methods/
# using CodecXz

function blob2PC(blob::PyObject)
    PC = Tuple{Float64,Float64,Float64}[]
    fh = blob.open()
    for line in fh
        startswith(line, "ATOM") || continue
        l = split(line)
        l[4] == "CA" || continue
        push!(PC, (parse(Float64,l[11]), parse(Float64,l[12]), parse(Float64,l[13])))
    end
    fh.close()
    PC
end

PC2PH(PC::Vector{Tuple{Float64,Float64,Float64}}) = ripserer(Alpha(PC); dim_max=2, alg=:involuted)

barcodes(PH, dim::Int) = hcat(collect.(collect(PH[dim+1]))...)'
representatives(PH, dim::Int) = [[collect(r.simplex) for r in collect(c)] for c in representative.(PH[dim+1])]

for blob in py"gen_blobs"()
    # discard "AF-" ... "-model_v3.cif"
    name = blob.name[4:end-13]
    outdir = "PH/"*name[1:2]*"/"*name[3:4]
    outfile = outdir*"/"*name*".json.gz"
    isfile(outfile) && continue
    mkpath(outdir)
    touch(outfile)
    PC = blob2PC(blob)
    n = length(PC)
    println(name, " ", n)
    PH = PC2PH(PC)
    dic = Dict(:n => n,
               :x => [p[1] for p in PC],
               :y => [p[2] for p in PC],
               :z => [p[3] for p in PC],
               :H1 => Dict(:barcode => barcodes(PH,1), :representatives => representatives(PH,1)),
               :H2 => Dict(:barcode => barcodes(PH,2), :representatives => representatives(PH,2)))
    GZip.open(outfile, "w") do io JSON.print(io, dic) end
    # on n=394: 46k instead of 56k but 0.064s instead of 0.022s.
    # open(XzCompressorStream, outfile, "w") do io JSON.print(io, dic) end
end

