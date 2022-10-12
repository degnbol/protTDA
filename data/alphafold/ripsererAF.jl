#!/usr/bin/env julia
using Ripserer
using PyCall
@pyinclude "fetch.py"
using JSON
using .Threads: @threads

mat2PC(mat::Matrix{Float64}) = mat |> eachrow .|> Tuple
xyz2PH(mat::Matrix{Float64}) = ripserer(Alpha(mat2PC(mat)); dim_max=2, alg=:involuted)

barcodes(PH, dim::Int) = hcat(collect.(collect(PH[dim+1]))...)'
representatives(PH, dim::Int) = [[collect(r.simplex) for r in collect(c)] for c in representative.(PH[dim+1])]


@threads for (name, xyz) in py"gen_xyzs"(max_results=100, max_size=100000)
    # discard "AF-" ... "-model_v3"
    name = name[4:end-9]
    println(name, " ", size(xyz,1))
    outdir = name[1:2]*"/"*name[3:4]
    outfile = outdir*"/"*name*".json.gz"
    isfile(outfile) && continue
    println(name)
    mkpath(outdir)
    touch(outfile)
    X = args.header ? Matrix(CSV.read(fname, DataFrame)[!, split("xyz","")]) : readdlm(fname)
    PH = xyz2PH(X)
    dic = Dict(:H1 => Dict(:barcode => barcodes(PH,1), :representatives => representatives(PH,1)),
               :H2 => Dict(:barcode => barcodes(PH,2), :representatives => representatives(PH,2)))
    GZip.open(outfile, "w") do io JSON.print(io, d) end
end

