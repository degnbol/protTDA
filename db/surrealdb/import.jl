#!/usr/bin/env julia
using JSON3, GZip
using HTTP, Base64

dir = expanduser("~/protTDA/data/alphafold/PH/100/100-0/")
fnames = readdir(dir)[1:100];
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
    id::String
    x::Float64
    y::Float64
    z::Float64
    cent1::Float64
    cent2::Float64
end
function Ca(acc::T, i::Int, x::Float64, y::Float64, z::Float64, cent1::Float64, cent2::Float64) where T<:AbstractString
    Ca("$(acc)_$i", x, y, z, cent1, cent2)
end
function Base.string(ca::Ca)
    "CREATE Ca:$(ca.id) SET
    x = $(ca.x),
    y = $(ca.y),
    z = $(ca.z),
    cent1 = $(ca.cent1),
    cent2 = $(ca.cent2);
    "
end

struct Simplex1
    id::String
    v1::String
    v2::String
end
function Simplex1(acc::T, rep::Int, i::Int, v1::Int, v2::Int) where T<:AbstractString
    Simplex1("$(acc)_$(rep)_$(i)", "$(acc)_$(v1)", "$(acc)_$(v2)")
end
function Base.string(simplex::Simplex1)
    "CREATE Simplex1:$(simplex.id) SET
    v1 = $(simplex.v1),
    v2 = $(simplex.v2);
    "
end

struct Simplex2
    id::String
    v1::String
    v2::String
    v3::String
end
function Simplex2(acc::T, rep::Int, i::Int, v1::Int, v2::Int, v3::Int) where T<:AbstractString
    Simplex2("$(acc)_$(rep)_$(i)", "$(acc)_$(v1)", "$(acc)_$(v2)", "$(acc)_$(v3)")
end
function Base.string(simplex::Simplex2)
    "CREATE Simplex2:$(simplex.id) SET
    v1 = $(simplex.v1),
    v2 = $(simplex.v2),
    v3 = $(simplex.v3);
    "
end

struct Rep1
    id::String
    birth::Float64
    death::Float64
    persistence::Float64
    simplices::Vector{String}
end
function Rep1(acc::T, i::Int, birth::Float64, death::Float64, simplices::Int) where T<:AbstractString
    Rep1("$(acc)_$(i)", birth, death, death - birth, ["Simplex1:$(acc)_$(i)_$(j)" for j in 1:simplices])
end
function Base.string(rep::Rep1)
    "CREATE Rep1:$(rep.id) SET
    birth = $(rep.birth),
    death = $(rep.death),
    persistence = $(rep.persistence),
    simplices = [$(join(rep.simplices, ','))];
    "
end

struct Rep2
    id::String
    birth::Float64
    death::Float64
    persistence::Float64
    simplices::Vector{String}
end
function Rep2(acc::T, i::Int, birth::Float64, death::Float64, simplices::Int) where T<:AbstractString
    Rep2("$(acc)_$(i)", birth, death, death - birth, ["Simplex2:$(acc)_$(i)_$(j)" for j in 1:simplices])
end
function Base.string(rep::Rep2)
    "CREATE Rep2:$(rep.id) SET
    birth = $(rep.birth),
    death = $(rep.death),
    persistence = $(rep.persistence),
    simplices = [$(join(rep.simplices, ','))];
    "
end

struct AFProt
    acc::String
    n::Int
    cas::Vector{String}
    reps1::Vector{String}
    reps2::Vector{String}
end
function AFProt(acc::T, n::Int, nRep1::Int, nRep2::Int) where T<:AbstractString
    AFProt(acc, n, ["Ca:$(acc)_$(i)" for i in 1:n], ["Rep1:$(acc)_$(i)" for i in 1:nRep1], ["Rep2:$(acc)_$(i)" for i in 1:nRep2])
end
function Base.string(prot::AFProt)
    "CREATE AFProt:$(prot.acc) SET
    n = $(prot.n),
    cas = [$(join(prot.cas, ','))],
    reps1 = [$(join(prot.reps1, ','))],
    reps2 = [$(join(prot.reps2, ','))];
    "
end

url = "http://localhost:8000/sql"
auth = Base64.base64encode("root:root")
headers = ["Authorization" => "Basic $auth", "NS" => "protTDA", "DB" => "alphafold", "Accept" => "application/json"]
post(body::Union{String,Vector{UInt8}}) = HTTP.post(url, headers, body)
post(body::Vector{String}) = HTTP.post(url, headers, join(body))
post(cas::Vector{Ca}, simplices1::Vector{Vector{Simplex1}}, simplices2::Vector{Vector{Simplex2}}, reps1::Vector{Rep1}, reps2::Vector{Rep2}, prot::AFProt) = begin
    creates = [cas; simplices1...; simplices2...; reps1; reps2; prot] .|> string
    n = length(creates)
    chunksize = 5000
    for chunk in 1:chunksize:n
        creates[chunk:min(chunk+chunksize-1,n)] |> post
    end
end


post("""
DEFINE TABLE Ca schemafull;
DEFINE TABLE Simplex1 schemafull;
DEFINE TABLE Simplex2 schemafull;
DEFINE TABLE Rep1 schemafull;
DEFINE TABLE Rep2 schemafull;
DEFINE TABLE AFProt schemafull;

DEFINE FIELD x on Ca type float;
DEFINE FIELD y on Ca type float;
DEFINE FIELD z on Ca type float;
DEFINE FIELD cent1 on Ca type float;
DEFINE FIELD cent2 on Ca type float;

DEFINE FIELD v1 on Simplex1 type record(Ca);
DEFINE FIELD v2 on Simplex1 type record(Ca);

DEFINE FIELD v1 on Simplex2 type record(Ca);
DEFINE FIELD v2 on Simplex2 type record(Ca);
DEFINE FIELD v3 on Simplex2 type record(Ca);

DEFINE FIELD birth on Rep1 type float;
DEFINE FIELD death on Rep1 type float;
DEFINE FIELD persistence on Rep1 type float;
DEFINE FIELD simplices on Rep1 type array;
DEFINE FIELD simplices.* on Rep1 type record(Simplex1);

DEFINE FIELD birth on Rep2 type float;
DEFINE FIELD death on Rep2 type float;
DEFINE FIELD persistence on Rep2 type float;
DEFINE FIELD simplices on Rep2 type array;
DEFINE FIELD simplices.* on Rep2 type record(Simplex2);

DEFINE FIELD acc on AFProt type string;
DEFINE FIELD n on AFProt type int;
DEFINE FIELD cas on AFProt type array;
DEFINE FIELD cas.* on AFProt type record(Ca);
DEFINE FIELD reps1 on AFProt type array;
DEFINE FIELD reps1.* on AFProt type record(Rep1);
DEFINE FIELD reps2 on AFProt type array;
DEFINE FIELD reps2.* on AFProt type record(Rep2);
""")


@time for (path, acc) in zip(paths, accs)
    println(acc)
    ph = GZip.open(path) do io ph = JSON3.read(io, PH) end
    cas = [Ca(acc,i,x,y,z,cent1,cent2) for (i, (x,y,z,cent1,cent2)) in enumerate(zip(ph.x, ph.y, ph.z, ph.cent1, ph.cent2))]
    simplices1 = [[Simplex1(acc,i,j,vs...) for (j,vs) in enumerate(rep)] for (i,rep) in enumerate(ph.reps1)]
    simplices2 = [[Simplex2(acc,i,j,vs...) for (j,vs) in enumerate(rep)] for (i,rep) in enumerate(ph.reps2)]
    reps1 = [Rep1(acc,i, birth, death, n) for (i,(birth,death,n)) in enumerate(zip(ph.bars1[1], ph.bars1[2], length.(simplices1)))]
    reps2 = [Rep2(acc,i, birth, death, n) for (i,(birth,death,n)) in enumerate(zip(ph.bars2[1], ph.bars2[2], length.(simplices2)))]
    prot = AFProt(acc, ph.n, length(reps1), length(reps2))
    post(cas, simplices1, simplices2, reps1, reps2, prot)
end

exit()

"Include : in table string"
function joinids(table::String, ids)
    '[' * join(("$table$i" for i in ids), ", ") * ']'
end

function create(table::String; fields...)
    fields_str = join([join(f, " = ") for f in fields], ",\n")
    println("CREATE $table SET\n$fields_str\n;")
end

function printSQL(acc::T, ph::PH) where T <: AbstractString
    for (i, (x,y,z,cent1,cent2)) in enumerate(zip(ph.x, ph.y, ph.z, ph.cent1, ph.cent2))
        create("Ca:$(acc)_$i"; x=x, y=y, z=z, cent1=cent1, cent2=cent2)
    end
    
    for (i, (birth, death, rep)) in enumerate(zip(ph.bars1[1], ph.bars1[2], ph.reps1))
        for (j, simplex) in enumerate(rep)
            create("Simplex1:$(acc)_$(i)_$(j)"; verts=joinids("Ca:$(acc)_", simplex))
        end
        create("Rep1:$(acc)_$(i)"; birth=birth, death=death, simplices=joinids("Simplex1:$(acc)_$(i)_", 1:length(rep)))
    end
    
    create("AFProt:$acc"; acc=acc, n=ph.n, cas=joinids("Ca:$(acc)_", 1:ph.n))
end

println(stderr, "Starting")

for (i, (path, acc)) in enumerate(zip(paths, accs))
    GZip.open(path) do io
        println(stderr, acc)
        printSQL(acc, JSON3.read(io, PH))
        flush(stdout)
    end;
end



