#!/usr/bin/env julia
using JSON3, GZip

dir = expanduser("~/protTDA/data/alphafold/PH/100/100-0/")
fnames = readdir(dir)[1:1000];
fnames = fnames[startswith.(fnames, "AF")];
accs = [split(f, '-')[2] for f in fnames];
paths = joinpath.(dir, fnames);

struct PH
    n::Int
    x::Vector{Float64}
    y::Vector{Float64}
    z::Vector{Float64}
    cent1::Vector{Float64}
    cent2::Vector{Float64}
    bars1::Vector{Vector{Float64}}
    bars2::Vector{Vector{Float64}}
    reps1::Vector{Vector{Vector{Int}}}
    reps2::Vector{Vector{Vector{Int}}}
end

struct Ca
    type::String
    x::Float64
    y::Float64
    z::Float64
    cent1::Float64
    cent2::Float64
end
function Ca(x::Float64, y::Float64, z::Float64, cent1::Float64, cent2::Float64)
    Ca("Ca", x, y, z, cent1, cent2)
end

struct Simplex1
    type::String
    v1::Int
    v2::Int
end
Simplex1(v1::Int, v2::Int) = Simplex1("Simplex1", v1, v2)

struct Simplex2
    type::String
    v1::Int
    v2::Int
    v3::Int
end
Simplex2(v1::Int, v2::Int, v3::Int) = Simplex2("Simplex2", v1, v2, v3)

struct Rep1
    type::String
    birth::Float64
    death::Float64
    persistence::Float64
    simplices::Vector{Simplex1}
end
function Rep1(birth::Float64, death::Float64, simplices::Vector{Simplex1})
    Rep1("Rep1", birth, death, death - birth, simplices)
end

struct Rep2
    type::String
    birth::Float64
    death::Float64
    persistence::Float64
    simplices::Vector{Simplex2}
end
function Rep2(birth::Float64, death::Float64, simplices::Vector{Simplex2})
    Rep2("Rep2", birth, death, death - birth, simplices)
end

struct AFProt
    type::String
    acc::String
    n::Int
    cas::Vector{Ca}
    reps1::Vector{Rep1}
    reps2::Vector{Rep2}
end
function AFProt(acc::T, ph::PH) where T<:AbstractString
    cas = [Ca(x,y,z,cent1,cent2) for (x,y,z,cent1,cent2) in zip(ph.x, ph.y, ph.z, ph.cent1, ph.cent2)]
    reps1 = [Rep1(birth, death, [Simplex1(vs...) for vs in rep]) for (birth,death,rep) in zip(ph.bars1[1], ph.bars1[2], ph.reps1)]
    reps2 = [Rep2(birth, death, [Simplex2(vs...) for vs in rep]) for (birth,death,rep) in zip(ph.bars2[1], ph.bars2[2], ph.reps2)]
    AFProt("AFProt", acc, ph.n, cas, reps1, reps2)
end



prots = Vector{AFProt}(undef, length(fnames))
for (i, (path, acc)) in enumerate(zip(paths, accs))
    GZip.open(path) do io
        prots[i] = AFProt(acc, JSON3.read(io, PH))
    end;
end
JSON3.write(prots) |> println

