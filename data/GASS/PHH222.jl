#!/usr/bin/env julia
using JSON

mkpath("PH_H1/")
mkpath("PH_H2/")

for fname in readdir("PHH2m/")
    d = JSON.parsefile("PHH2m/$fname")
    open("PH_H1/$fname", "w") do io JSON.print(io, d["H1"]) end
    open("PH_H2/$fname", "w") do io JSON.print(io, d["H2"]) end
end
