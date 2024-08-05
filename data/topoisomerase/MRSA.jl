#!/usr/bin/env julia
using DataFrames, CSV
using HDF5, H5Zzstd
using PlotlyJS
using Colors, ColorSchemes
using Printf
using BioAlignments, BioSequences

using Graphs
using SimpleWeightedGraphs

using PyCall

ROOT = `git root` |> readchomp
include("$ROOT/src/util/plotly.jl")
using Chain

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

# read AF HDF5s
Cas_AF = Matrix{Float32}[]
bars1_AF = Matrix{Float32}[]
bars2_AF = Matrix{Float32}[]
reps1_AF = Matrix{Int32}[]
reps2_AF = Matrix{Int32}[]
for acc in df.acc
    h5open("HDF5/$(acc[1:5]).h5") do fid
        g = fid[acc]
        # x, y, z, pLDDT, cent1, cent2
        push!(Cas_AF, g["Cas"][:,:])
        # birth, death
        push!(bars1_AF, g["bars1"][:,:])
        push!(bars2_AF, g["bars2"][:,:])
        # representative index, vertex 1, vertex 2 (one edge per row)
        push!(reps1_AF, g["reps1"][:,:])
        # representative index, vertex 1, vertex 2, vertex 3 (one triangle per row)
        push!(reps2_AF, g["reps2"][:,:])
    end
end
# AF structures simply run along the sequence from 1 to finish, 
# as opposed to solved structure which may have gaps or start later than 1.
resis_AF = [1:n for n in df.n]

# read solved structure HDF5s
fnames_PH = readdir("PH/")
# skip failed structures with NaN, TODO: rerun PH where NaN is removed
fnames_PH = fnames_PH[.!startswith.(fnames_PH, "1r49_C_1")]
pdbs = String[]
accs = String[]
Cas = Matrix{Float32}[]
bars1 = Matrix{Float32}[]
bars2 = Matrix{Float32}[]
reps1 = Matrix{Int32}[]
reps2 = Matrix{Int32}[]
resis = Vector{Int32}[]
for fname in fnames_PH
    acc = split(split(fname, '-')[end], '.')[1]
    acc ∈ df.acc || continue
    push!(pdbs, split(fname, '-')[begin])
    push!(accs, acc)
    h5open("PH/$fname") do fid
        g = fid # top-level
        # x, y, z, pLDDT, cent1, cent2
        push!(Cas, g["Cas"][:,:])
        # birth, death
        push!(bars1, g["bars1"][:,:])
        push!(bars2, g["bars2"][:,:])
        # representative index, vertex 1, vertex 2 (one edge per row)
        push!(reps1, g["reps1"][:,:])
        # representative index, vertex 1, vertex 2, vertex 3 (one triangle per row)
        push!(reps2, g["reps2"][:,:])
        push!(resis, attrs(g)["resi"])
    end
end

# There is one AF PH per row of df currently.
# Add rows to dataframe for each PH on solved structure.
Cas = [Cas_AF; Cas]
bars1 = [bars1_AF; bars1]
bars2 = [bars2_AF; bars2]
reps1 = [reps1_AF; reps1]
reps2 = [reps2_AF; reps2]
resis = [resis_AF; resis]
newrows = DataFrameRow[]
for i in 1:length(pdbs)
    ii = i+nrow(df)
    row = df[df.acc .== accs[i], :] |> only
    row.pdb = pdbs[i]
    row.meanplddt = NaN
    # there may be negative resi indexes if a few amino acids are added before the sequence (e.g. https://www.rcsb.org/3d-view/5GVC)
    # we just name them X, but if you want to include their AA name, then you will need to write the AA sequence with them to the HDF5 file made in ./PH.sh
    _resis = resis[ii]
    prelude = _resis .< 1
    row.n = length(_resis)
    row.sequence = 'X' ^ sum(prelude) * row.sequence[_resis[.!prelude]]
    row.nrep1 = reps1[ii][end,1]
    row.nrep2 = reps2[ii][end,1]
    for t in 1:10
        row["nrep1_t$t"] = sum(bars1[ii][:,2] .> t)
    end
    for t in .1:.1:1.
        row[rstrip(@sprintf("nrep2_t%02d", 10*t),'0')] = sum(bars2[ii][:,2] .> t)
    end
    row.maxrep1 = countmap(reps1[ii][:,1]) |> values |> maximum
    row.maxrep2 = countmap(reps2[ii][:,1]) |> values |> maximum
    row.maxpers1 = maximum(bars1[ii][:,2])
    row.maxpers2 = maximum(bars2[ii][:,2])
    push!(newrows, row)
end
append!(df, newrows)

seqs = [join.(zip(resis[i], df.sequence[i])) for i in 1:nrow(df)]

titles = df.acc .* '-' .* [fill("AF", nrow(df) - length(pdbs)); pdbs]

top1 = (1:nrow(df))[startswith.(df.name, "TOP1")]
top3 = (1:nrow(df))[startswith.(df.name, "TOP3")]

## PLOTTING

# persistence diagrams
function scat(i)
    scatter(;
            x=bars1[i][:, 1],
            y=vec(sum(bars1[i], dims=2)),
            mode="markers",
            name=titles[i],
            )
end
function subplots(traces)
    nrows = floor(Int, √length(traces))
    ncols = ceil(Int, length(traces) / nrows)
    fig = make_subplots(cols=ncols, rows=nrows)
    for (i, trace) in enumerate(traces)
        add_trace!(fig, trace, row=(i-1) ÷ ncols + 1, col=(i-1) % ncols + 1)
    end
    fig
end
function square_subplots!(fig, xyrange)
    relayout!(
        fig;
        yaxes(fig, scaleanchor="x" .* [""; string.(2:length(top1))])...,
        xaxes(fig, range=Ref(xyrange))...,
        yaxes(fig, range=Ref(xyrange))...,
    )
    fig
end

pltDiagramTOP1 = @chain scat.(top1) subplots square_subplots!([0, 50])
pltDiagramTOP3 = @chain scat.(top3) subplots square_subplots!([0, 50])
relayout!(pltDiagramTOP1, title_text="TOP1")
relayout!(pltDiagramTOP3, title_text="TOP3")
savefig(pltDiagramTOP1, "figs/persistence_diagrams-TOP1.html")
savefig(pltDiagramTOP3, "figs/persistence_diagrams-TOP3.html")

topn1 = 10
topn2 = 20
# categorical palette with high chroma (minc=20)
# palette = ColorSchemes.glasbey_category10_n256
palette = ColorSchemes.glasbey_bw_minc_20_minl_30_n256
rgbs = [[rgb.r, rgb.g, rgb.b] for rgb in palette]
rgbs = [round.(Int, rgb .* 255) for rgb in rgbs]
rgbs = ["rgb("*join(rgb,',')*')' for rgb in rgbs]

alltraces = []

mkpath("figs")
for i in 1:nrow(df)
    traces = [
        # main basic gray point cloud
        scatter3d(;
                  x=Cas[i][:, 1],
                  y=Cas[i][:, 2],
                  z=Cas[i][:, 3],
                  marker_size=5,
                  marker_color="gray",
                  name=titles[i],
                  text=seqs[i],
                  )
    ]

    # plddt if predicted structure
    any(isnan.(Cas[i][:, 4])) ||
    push!(traces,
          scatter3d(;
                    x=Cas[i][:, 1],
                    y=Cas[i][:, 2],
                    z=Cas[i][:, 3],
                    marker_size=5,
                    marker_color=Cas[i][:, 4],
                    mode="markers",
                    name="pLDDT (prediction quality)",
                    visible="legendonly",
                    text=Cas[i][:, 4],
                    )
          );

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
    _colors = [c > 0 && c ≤ length(rgbs) ? rgbs[c] : "gray" for c in comm]
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
    _colors = [c > 0 && c ≤ length(rgbs) ? rgbs[c] : "gray" for c in comm]
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

    push!(alltraces, traces)

    plt = plot(traces,
               Layout(;
                      title_text=df.name[i],
                      bgcolor="lightgray",
               );
               config=PlotConfig(
            displaylogo=false,
            # showTips=false # not implemented in the julia version and last change to the github was 5 months ago.
        ))

    savefig(plt, "figs/$(df.name[i])-$(titles[i]).html")
end


# align sequences to compare
seqs = LongAA.(df.sequence)
costmodel = AffineGapScoreModel(BLOSUM62, gap_open=-10, gap_extend=-1)
align47 = pairalign(OverlapAlignment(), seqs[4], seqs[7], costmodel)
align74 = pairalign(OverlapAlignment(), seqs[7], seqs[4], costmodel)

xs = Int[]
x = 0
skip = 0
for (seqAA, refAA) in collect(align74.aln)
    if refAA != AA_Gap
        x += 1
    end
    if seqAA != AA_Gap
        push!(xs, x)
    end
end

plt = [
plot([
    scatter(;
            y=Cas[4][:,5],
            name="MRSA cent1",
            mode="lines",
    ),
    scatter(;
            y=Cas[7][:,5],
            name="Human cent1",
            mode="lines",
            visible="legendonly",
    ),
    scatter(;
            x=xs[xs .> 0],
            y=Cas[7][xs .> 0,5],
            name="Human cent1 aligned",
            mode="markers+lines",
            line_width=1.5,
            marker_size=5,
            text=(1:sum(xs .> 0)) .+ sum(xs .== 0),
    ),
    ])
plot([
    scatter(;
            y=Cas[4][:,6],
            name="MRSA cent2",
            mode="lines",
    ),
    scatter(;
            y=Cas[7][:,6],
            name="Human cent2",
            mode="lines",
            visible="legendonly",
    ),
    scatter(;
            x=xs[xs .> 0],
            y=Cas[7][xs .> 0,6],
            name="Human cent2 aligned",
            mode="markers+lines",
            line_width=1.5,
            marker_size=5,
            text=(1:sum(xs .> 0)) .+ sum(xs .== 0),
    ),
    ])
]
savefig(plt, "figs/MRSA-centAlign.html")


trace = alltraces[4]
push!(trace,
      scatter3d(;
                x=Cas[4][300:450, 1],
                y=Cas[4][300:450, 2],
                z=Cas[4][300:450, 3],
                marker=attr(
                size=5,
                color="red",
                ),
                mode="markers+lines",
                name="cent1 difference",
                )
      )

plt = plot(trace);
savefig(plt, "figs/MRSA-diff.html")

