#!/usr/bin/env julia
using Ripserer
using PyCall
@pyinclude "fetch.py"
using JSON
using .Threads: @threads
using ThreadsX
using ThreadPools
using FLoops

mat2PC(mat::Matrix{Float64}) = mat |> eachrow .|> Tuple
xyz2PH(mat::Matrix{Float64}) = ripserer(Alpha(mat2PC(mat)); dim_max=2, alg=:involuted)

barcodes(PH, dim::Int) = hcat(collect.(collect(PH[dim+1]))...)'
representatives(PH, dim::Int) = [[collect(r.simplex) for r in collect(c)] for c in representative.(PH[dim+1])]

function main(name::String, xyz::Matrix{Float64})
    # discard "AF-" ... "-model_v3"
    name = name[4:end-9]
    println(name, " ", size(xyz,1))
    outdir = name[1:2]*"/"*name[3:4]
    outfile = outdir*"/"*name*".json.gz"
    isfile(outfile) && return
    println(name)
    mkpath(outdir)
    touch(outfile)
    PH = xyz2PH(xyz)
    dic = Dict(:H1 => Dict(:barcode => barcodes(PH,1), :representatives => representatives(PH,1)),
               :H2 => Dict(:barcode => barcodes(PH,2), :representatives => representatives(PH,2)))
    GZip.open(outfile, "w") do io JSON.print(io, dic) end
end

gen = py"gen_xyzs"(max_results=1, max_size=0)


@threads for (name, xyz) in gen
    main(name, xyz)
end

@qthreads for (name, xyz) in gen
    main(name, xyz)
end

@bthreads for (name, xyz) in gen
    main(name, xyz)
end

@qbthreads for (name, xyz) in gen
    main(name, xyz)
end

@floop for (name, xyz) in gen
    main(name, xyz)
end

tmap(main, gen)
bmap(main, gen)
qmap(main, gen)
qbmap(main, gen)
tforeach(main, gen)
bforeach(main, gen)
qforeach(main, gen)
qbforeach(main, gen)
ThreadsX.foreach(main, gen)
ThreadsX.map(main, gen)
ThreadsX.map!(main, gen)

