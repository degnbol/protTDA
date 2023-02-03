#!/usr/bin/env julia
include("mongo.jl")

@time res = mg.find(af, "pers1" => D("\$elemMatch" => D("\$gt" => 4)); projection=D("_id" => 1)) |> collect
println(length(res), "/", length(af))

