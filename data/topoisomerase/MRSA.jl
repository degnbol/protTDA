#!/usr/bin/env julia
using DataFrames, CSV
using HDF5, H5Zzstd
filters = H5Zzstd.ZstdFilter()
using PlotlyJS
using Colors, ColorSchemes
using GZip, JSON
using Glob: glob
using Printf

using Graphs
using SimpleWeightedGraphs

using PyCall
# leiden = pyimport("leidenalg")
# igraph constructor that takes list of (source, destination, edge property) tuple
ig = pyimport("igraph").Graph.TupleList

function Graphs.SimpleGraph(edges::Matrix{Int32})
    edges |> eachrow .|> Tuple .|> Graphs.SimpleEdge |> SimpleGraph
end

function Graphs.cycle_basis(edges::Matrix{Int32})::Vector{Vector{Int32}}
    cycles = edges |> SimpleGraph |> cycle_basis
    # each cycle doesn't wrap around from Graphs.cycle_basis
    for cycle in cycles
        push!(cycle, cycle[begin])
    end
    cycles
end

using SparseArrays

"""
B is sparse integer matrix with dim (#nodes, #hyperedges).
- hyperedges: each hyperedge is a set of node indices
- nNodes: optionally specify the total number of nodes
"""
function hyperedges2B(hyperedges::Vector{Set{Int}}, nNodes::Union{Int,Nothing}=nothing)
    Is = [n for     h  in           hyperedges  for n in h] 
    Js = [j for (j, h) in enumerate(hyperedges) for n in h]
    if nNodes === nothing
        sparse(Is, Js, 1)
    else
        sparse(Is, Js, 1, nNodes, length(hyperedges))
    end
end

function reps2hyperedges(reps::Matrix{Int32})
    hyperedges = Set{Int}[]
    indices = reps[:,1]
    _reps = Int.(reps[:,2:end])
    for i in 1:maximum(indices)
        push!(hyperedges, Set(_reps[indices .== i, :]))
    end
    hyperedges
end

function CliqueExpansion(mat)
    N = size(mat, 1)
    ex = zeros(N, N)
    for he in eachcol(mat)
        Is = findall(he .!= 0)
        for i in Is
            for j in Is
                if i != j
                    ex[i,j] = (he[i] + he[j]) / 2
                end
            end
        end
    end
    ex
end

@pyinclude "/Users/cdmadsen/Documents/hyperTDA/src/leiden.py"


function leiden(reps, bars, n)
    B = hyperedges2B(reps2hyperedges(reps), n)
    persistences = bars[:,end]
    H = B .* persistences'
    H |> CliqueExpansion |> py"leiden"
end

## READ

df = CSV.read("MRSA-AF.tsv", DataFrame; delim='\t')

# read HDF5s
Cas = Matrix{Float32}[]
bars1 = Matrix{Float32}[]
bars2 = Matrix{Float32}[]
reps1 = Matrix{Int32}[]
reps2 = Matrix{Int32}[]
for acc in df.acc
    h5open("HDF5/$(acc[1:5]).h5") do fid
        g = fid[acc]
        # x, y, z, pLDDT, cent1, cent2
        push!(Cas, g["Cas"][:,:])
        # birth, death
        push!(bars1, g["bars1"][:,:])
        push!(bars2, g["bars2"][:,:])
        # representative index, vertex 1, vertex 2 (one edge per row)
        push!(reps1, g["reps1"][:,:])
        # representative index, vertex 1, vertex 2, vertex 3 (one triangle per row)
        push!(reps2, g["reps2"][:,:])
    end
end

jsons = Dict{String,Vector{Dict{String,Any}}}()
for fname in glob("PH/*/*.json.gz")
    acc = split(split(basename(fname), '-')[end], '.')[1]
    if !haskey(jsons, acc) jsons[acc] = [] end
    push!(jsons[acc], GZip.open(fname) do io
        JSON.parse(io)
    end)
end

# add to arrays from HDF5s
df[!, :pos] .= 1
newrows = DataFrameRow[]
for (acc, _jsons) in jsons
    for _json in _jsons
        _bars1 = hcat(_json["bars1"]...)
        _bars2 = hcat(_json["bars2"]...)
        # HDF5 stored bars have persistence in second column
        _bars1[:,2] .-= _bars1[:,1]
        _bars2[:,2] .-= _bars2[:,1]
        row = df[df.acc .== acc, :] |> only
        row.meanplddt = NaN
        row.pos = _json["pos"]
        row.n = _json["n"]
        row.sequence = row.sequence[row.pos:end][1:row.n]
        row.nrep1 = length(_json["reps1"])
        row.nrep2 = length(_json["reps2"])
        for t in 1:10
            row["nrep1_t$t"] = sum(_bars1[:,2] .> t)
        end
        for t in .1:.1:1.
            row[rstrip(@sprintf("nrep2_t%02d", 10*t),'0')] = sum(_bars2[:,2] .> t)
        end
        row.maxrep1 = length.(_json["reps1"]) |> maximum
        row.maxrep2 = length.(_json["reps2"]) |> maximum
        row.maxpers1 = maximum(_bars1[:,2])
        row.maxpers2 = maximum(_bars2[:,2])
        _json["pLDDT"] = fill(NaN32, length(_json["x"]))
        _Cas = hcat([_json[k] for k in ["x","y","z","pLDDT","cent1","cent2"]]...)
        _reps1 = zeros(Int32, 0, 3)
        _reps2 = zeros(Int32, 0, 4)
        for (iRep,rep) in enumerate(_json["reps1"])
            _rep = hcat(rep...)'
            _reps1 = vcat(_reps1, [fill(iRep,size(_rep,1)) _rep])
        end
        for (iRep,rep) in enumerate(_json["reps2"])
            _rep = hcat(rep...)'
            _reps2 = vcat(_reps2, [fill(iRep,size(_rep,1)) _rep])
        end
        push!(newrows, row)
        push!(Cas, _Cas)
        push!(bars1, _bars1)
        push!(bars2, _bars2)
        push!(reps1, _reps1)
        push!(reps2, _reps2)
    end
end
append!(df, newrows)

# remove the poor predictions
df = df[Not(7),:]
Cas = Cas[Not(7)]
bars1 = bars1[Not(7)]
bars2 = bars2[Not(7)]
reps1 = reps1[Not(7)]
reps2 = reps2[Not(7)]

top1 = (1:nrow(df))[startswith.(df.name, "TOP1")]
top3 = (1:nrow(df))[startswith.(df.name, "TOP3")]

# persistence diagrams
function scat(i)
    plot(
        scatter(;
                x=bars1[i][:, 1],
                y=vec(sum(bars1[i], dims=2)),
                mode="markers",
                name=df.name[i]
                ),
        Layout(
            xaxis_range=[0, 50],
            yaxis_range=[0, 50]
        )
    )
end
vcat([scat(i) for i in top1]...)
vcat([scat(i) for i in top3]...)


topn1 = 10
topn2 = 20
# categorical palette with high chroma (minc=20)
# palette = ColorSchemes.glasbey_category10_n256
palette = ColorSchemes.glasbey_bw_minc_20_minl_30_n256
rgbs = [[rgb.r, rgb.g, rgb.b] for rgb in palette]
rgbs = [round.(Int, rgb .* 255) for rgb in rgbs]
rgbs = ["rgb("*join(rgb,',')*')' for rgb in rgbs]

mkpath("figs")
for i in 1:nrow(df)
    seq = collect(df.sequence[i])

    traces = [
        # main basic gray point cloud
        scatter3d(;
                  x=Cas[i][:, 1],
                  y=Cas[i][:, 2],
                  z=Cas[i][:, 3],
                  marker_size=5,
                  marker_color="gray",
                  name=df.name[i],
                  text=join.(zip(seq, (1:length(seq)) .+ df.pos[i])),
                  )
    ]

    # cent1
    push!(traces,
          scatter3d(;
                    x=Cas[i][:, 1],
                    y=Cas[i][:, 2],
                    z=Cas[i][:, 3],
                    marker_size=5,
                    marker_color=Cas[i][:, 5],
                    mode="markers",
                    name="cent1",
                    visible="legendonly",
                    text=Cas[i][:, 5],
                    )
          );

    # cent2
    push!(traces,
          scatter3d(;
                    x=Cas[i][:, 1],
                    y=Cas[i][:, 2],
                    z=Cas[i][:, 3],
                    marker_size=5,
                    marker_color=Cas[i][:, 6],
                    mode="markers",
                    name="cent2",
                    visible="legendonly",
                    text=Cas[i][:, 6],
                    )
          );

    # comm1
    comm = leiden(reps1[i], bars1[i], size(Cas[i],1))
    _colors = [c > 0 ? rgbs[c] : "gray" for c in comm]
    push!(traces,
          scatter3d(;
                    x=Cas[i][:, 1],
                    y=Cas[i][:, 2],
                    z=Cas[i][:, 3],
                    marker=attr(
                    size=5,
                    color=_colors,
                    ),
                    mode="markers",
                    name="Leiden 1",
                    visible="legendonly",
                    text=comm,
                    )
          );

    # comm2
    comm = leiden(reps2[i], bars2[i], size(Cas[i],1))
    _colors = [c > 0 ? rgbs[c] : "gray" for c in comm]
    push!(traces,
          scatter3d(;
                    x=Cas[i][:, 1],
                    y=Cas[i][:, 2],
                    z=Cas[i][:, 3],
                    marker=attr(
                    size=5,
                    color=_colors,
                    ),
                    mode="markers",
                    name="Leiden 2",
                    visible="legendonly",
                    text=comm,
                    )
          );

    # reps1
    maxind = size(bars1[i],1)
    for top in 1:topn1
        rep = reps1[i][reps1[i][:,1] .== maxind - top + 1, 2:3]
        cycles = cycle_basis(rep)
        persistence = bars1[i][end-top+1,2]
        opacity = persistence / bars1[i][end,2] * .9
        for (i_cycle, cycle) in enumerate(cycles)
            push!(traces,
                  scatter3d(;
                            x=Cas[i][cycle, 1],
                            y=Cas[i][cycle, 2],
                            z=Cas[i][cycle, 3],
                            mode="lines",
                            line_color=rgbs[top],
                            line_width=16,
                            opacity=opacity,
                            name="rep1 $top",
                            text="persistence=$persistence",
                            legendgroup="rep1 $top",
                            visible="legendonly",
                            # combined with legendgroup, this means multiple 
                            # cycles for a single homology group will be 
                            # toggled together implicity.
                            showlegend=i_cycle==1,
                            )
                  );
        end
    end

    # reps2
    maxind = size(bars2[i],1)
    _ijk = reps2[i][reps2[i][:,1] .> maxind - topn2, :]
    persistences = bars2[i][end-topn2+1:end,2]
    opacities = persistences./maximum(persistences) .* .9
    # rgbs = palette[maxind .- _ijk[:,1] .+ 1]
    # rgbs = hcat([[rgb.r, rgb.g, rgb.b] for rgb in rgbs]...)'
    # rgbs = round.(Int, rgbs .* 255)
    for top in 1:topn2
        push!(traces,
              mesh3d(;
                     x=Cas[i][:, 1],
                     y=Cas[i][:, 2],
                     z=Cas[i][:, 3],
                     i=_ijk[_ijk[:,1].==maxind-top+1,2],
                     j=_ijk[_ijk[:,1].==maxind-top+1,3],
                     k=_ijk[_ijk[:,1].==maxind-top+1,4],
                     opacity=opacities[end-top+1],
                     text="persistence=$(persistences[end-top+1])",
                     name="rep2 $top",
                     showlegend=true,
                     visible="legendonly"
                     )
              )
    end

    plt = plot(traces,
               Layout(;
                   title_text="Start position=$(df.pos[i])",
                      bgcolor="lightgray",
               );
               config=PlotConfig(
            displaylogo=false,
            # showTips=false # not implemented in the julia version and last change to the github was 5 months ago.
        ))

    savefig(plt, "figs/$(df.name[i])_pos$(df.pos[i]).html")
end




