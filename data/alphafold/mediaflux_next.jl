#!/usr/bin/env julia
using Random
using Tar

for retries in 1:100

    d0s = readdir("PH"; join=true)
    d0s = d0s[match.(r"^[0-9-]", basename.(d0s)) .!= nothing]
    d1s = vcat(readdir.(d0s; join=true)...)

    mf1s = vcat(readdir.(readdir("PH/MF"; join=true))...)
    mf1s = [splitext(f)[1] for f in basename.(mf1s)]
    todo = setdiff(basename.(d1s), mf1s)
    
    println(length(todo), " todo")
    length(todo) > 0 || exit()

    shuffle!(todo)

    batch_size = 1000
    batch = todo[1:min(length(todo), batch_size)]

    for tax in batch
        println(tax)
        outdir = "PH/MF/$(tax[1:3])"
        mkpath(outdir)
        outfile = "$outdir/$tax.tar"
        isfile(outfile) || Tar.create("PH/$(tax[1:3])/$tax", outfile)
    end

end
