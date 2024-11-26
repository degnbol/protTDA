#!/usr/bin/env julia
using DataFrames
using Gadfly
# for PDF
import Cairo, Fontconfig

df = DataFrame(nPersist=Int[],
               N=Int[],
               duration=Float64[],
               time=Int[],
               fsUsedSize=Int[],
               objects=Union{Missing,Int}[],
               avgObjSize=Union{Missing,Float64}[],
               dataSize=Union{Missing,Int}[],
               storageSize=Union{Missing,Int}[],
               indexSize=Union{Missing,Int}[],
               totalSize=Union{Missing,Int}[],
               lang=String[],)

Ts = df |> eachcol .|> eltype .|> nonmissingtype

open("query_speed.jl.out") do io
    for line in readlines(io)
        row = split(line, ' ')[[1, 3, 5, 7, 9]]
        row = [parse(T,v) for (v,T) in zip(row, Ts)]
        row = [row; [missing for _ in 1:6]; "jl"]
        push!(df, row)
    end
end

# reorder fsUsedSize to match order in file
df = df[!, [setdiff(names(df), ["fsUsedSize", "lang"]); "fsUsedSize"; "lang"]]

Ts = df |> eachcol .|> eltype .|> nonmissingtype

open("query_speed.js.out") do io
    for line in readlines(io)
        if !any(startswith.(line, collect("{} ")))
            global row = split(line, ' ')[[1, 3, 5, 7]]
        elseif startswith(line, ' ')
            key, val, = strip.(split(line, [':', ',']))
            key ∈ names(df) && push!(row, val)
        elseif startswith(line, '}')
            row = [parse(T,v) for (v,T) in zip(row, Ts)]
            push!(df, [row; "js"])
        end
    end
end

# set time relative to start
df = transform(groupby(df, :lang), :time => (x -> x .- minimum(x)) => :time)
# time is in ms for js and seconds for jl
df[df.lang .== "js", :time] .= round.(Int, df[df.lang .== "js", :time] ./ 1000)

# rename for nicer plotting
df.lang[df.lang .== "jl"] .= "Julia"
df.lang[df.lang .== "js"] .= "JavaScript"
rename!(df, :lang => "Language")

ylabs = Dict(
    "nPersist" => "Filtered proteins",
    "N" => "Queried proteins",
    "duration" => "Duration",
    "time" => "Time",
    "fsUsedSize" => "Disk usage",
    "objects" => "Objects",
    "avgObjSize" => "Average object size",
    "dataSize" => "Data size",
    "storageSize" => "Storage size",
    "indexSize" => "Index size",
    "totalSize" => "Total size"
)

plts = [
    plot(df, x="N", y=c, color=:Language, Guide.ylabel(ylabs[c]), Theme(key_position=:none))
    for c in setdiff(names(df), ["Language", "N"])
]


hstack(
    vstack(plts[1:3]..., plts[end-1]),
    vstack(plts[4:7]...),
    # add color legend
    vstack([plot(df, color=:Language, Geom.blank); [plot() for _ in 1:3]]...)
)

dfl = stack(df, setdiff(names(df), ["Language", "N"]))
# dropmissing!(dfl)

set_default_plot_size(12cm, 25cm)
plt = plot(dfl, x=:N, y=:value, ygroup=:variable, color=:Language, Geom.subplot_grid(Geom.point, free_y_axis=true), Guide.ylabel(""));
# plt
draw(PDF("query_speed.pdf"), plt)

