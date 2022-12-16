#!/usr/bin/env julia
using GZip, JSON
using Statistics

d2s = [d2 for d1 in readdir("PH"; join=true) for d2 in readdir(d1; join=true)]
louvains = joinpath.(d2s, "louvain.json.gz")
louvains = louvains[isfile.(louvains)]

# "AF-A0A4R1HH31-F1-model_v3" -> A0A4R1HH31
AF2acc(AF::String) = AF[4:end-12]


function read_xyz(PH_fname::String)
    PH = GZip.open(joinpath(dir, PH_fname)) do io
        JSON.parse(io)
    end
    hcat(PH["x"], PH["y"], PH["z"])
end

centerOfMass(coords::Matrix) = mean(coords, dims=1)

function radiusOfGyration(coords::Matrix)
    center = centerOfMass(coords)
    dists_sq = (coords .- center) .^ 2
    sqrt(mean(dists_sq))
end


N = length(louvains)
for (i, louvain) in enumerate(louvains)
    i % 1000 == 0 && println("$i/$N")
    
    H2comms = GZip.open(louvain) do io
        try JSON.parse(io)
        catch e
            println("ERROR parsing $louvain")
        end
    end
    H2comms !== nothing || continue
    dir = dirname(louvain)
    PH_fnames = [fname for fname in readdir(dir) if startswith(fname, "AF-")]
    pointclouds = Dict{String,Matrix{Float64}}()
    for fname in PH_fnames
        # AF-Q9RH31-F1-model_v3.json.gz -> Q9RH31
        acc = split(fname, '-')[2]
        pointclouds[acc] = read_xyz(joinpath(dir, fname))
    end
    
    
    for (H, AF2comm) in H2comms
        H == "H1" || continue
        for (AF, comms) in AF2comm
            acc = AF2acc(AF)
        end
    end
    for (H, AF2comm) in H2comms
        H == "H2" || continue
        for (AF, comms) in AF2comm
            acc = AF2acc(AF)
        end
    end
end

