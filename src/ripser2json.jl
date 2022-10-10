#!/usr/bin/env julia
# USE: ripser-representatives ... | ripser2json.jl > OUTFILE.json
using JSON
using Chain: @chain

dic = Dict{String,Dict}()

dim = -1
for line in readlines()
    if startswith(line, "persistence intervals in dim ")
        global dim = @chain split(line)[end] rstrip(':') parse(Int, _)
        if dim > 0
            dic["H$dim"] = Dict(:barcode=>Matrix{Float64}(undef,0,2), :representatives=>Vector{Vector{Vector{Int}}}())
        end
    elseif dim > 0
        bar = match(r"^ \[([0-9.]+),([0-9.]+)\): ", line)
        bar !== nothing || continue
        dic["H$dim"][:barcode] = vcat(dic["H$dim"][:barcode], parse.(Float64, bar.captures)')
        rx = "\\[" * join(["([0-9]+)" for _ in 1:dim+1], ',') * "\\]" |> Regex
        reps = [parse.(Int, m.captures) for m in eachmatch(rx, split(line, ':')[2])]
        push!(dic["H$dim"][:representatives], reps)
    end
end

JSON.print(dic, 2)
