#!/usr/bin/env julia

acc2path = Dict{String,String}()

d2s = [d2 for d1 in readdir("PH"; join=true) for d2 in readdir(d1; join=true)]

N = length(d2s)

for (i, d2) in enumerate(d2s)
    i % 1000 == 0 && println("$i/$N")
    for fname in readdir(d2)
        if startswith(fname, "AF-")
            # AF-Q9RH31-F1-model_v3.json.gz -> Q9RH31
            acc = fname[4:end-20]
            acc2path[acc] = joinpath(d2, fname)
        end
    end
end

using DelimitedFiles
writedlm("acc2path.tsv", [keys(acc2path) values(acc2path)])

