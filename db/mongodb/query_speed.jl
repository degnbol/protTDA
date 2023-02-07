#!/usr/bin/env julia
include("mongo.jl")

lastN = 0
open("query_speed.jl.out", "w") do io
    for _ in 1:10000
        while true
            global N = length(af)
            if N > lastN
                global lastN = N
                break
            else
                sleep(10)
            end
        end
        before = time()
        res = mg.find(af, "pers1" => D("\$elemMatch" => D("\$gt" => 4)); projection=D("_id" => 1)) |> collect
        after = time()
        du = filesize.(readdir("/home/opc/protTDA/xfs/mongo/"; join=true)) |> sum
        line = "$(length(res)) / $N duration: $(after - before) time: $(round(Int, after)) du: $du"
        println(io, line)
        println(line)
        flush(io)
        flush(stdout)
        sleep(10)
    end
end

