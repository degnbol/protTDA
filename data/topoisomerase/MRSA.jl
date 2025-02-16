#!/usr/bin/env julia
using GZip
using DataFrames, CSV
using HDF5, H5Zzstd
using PlotlyJS
using Colors, ColorSchemes
using Printf
using BioAlignments, BioSequences
using Graphs
using SimpleWeightedGraphs
using Chain
using StatsBase: countmap
using JSON3
ROOT = `git root` |> readchomp
include("$ROOT/src/util/plotly.jl")

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

## READ

df = CSV.read("MRSA-AF.tsv", DataFrame; delim='\t')
leidens = GZip.open("leidens.json.gz", "rb") do fp
    JSON3.read(fp)
end;

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
title2leiden = x -> replace(join(reverse(split(x, '-')), '-'), "AF-"=>"")

top1 = (1:nrow(df))[startswith.(df.name, "TOP1")]
top3 = (1:nrow(df))[startswith.(df.name, "TOP3")]

## PLOTTING

# persistence diagrams
function scat(i)
    scatter(;
            x=bars2[i][:, 1],
            y=vec(sum(bars2[i], dims=2)),
            mode="markers",
            name=titles[i],
            )
end
pltDiagramTOP1 = @chain scat.(top1) subplots square_subplots!([0, 50])
pltDiagramTOP3 = @chain scat.(top3) subplots square_subplots!([0, 50])

relayout!(pltDiagramTOP1, title_text="TOP1", template="simple_white")
relayout!(pltDiagramTOP3, title_text="TOP3", template="simple_white")

mkpath("figs")
# savefig(pltDiagramTOP1, "figs/persistence_diagrams_dim2-TOP1.html")
# savefig(pltDiagramTOP3, "figs/persistence_diagrams_dim2-TOP3.html")

topn1 = 10
topn2 = 20
# categorical palette with high chroma (minc=20)
# palette = ColorSchemes.glasbey_category10_n256
palette = ColorSchemes.glasbey_bw_minc_20_minl_30_n256
rgbs = [[rgb.r, rgb.g, rgb.b] for rgb in palette]
rgbs = [round.(Int, rgb .* 255) for rgb in rgbs]
rgbs = ["rgb("*join(rgb,',')*')' for rgb in rgbs]

alltraces = []
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
    any(isnan.(Cas[i][:, 4])) || all(Cas[i][:, 4] .< 0) ||
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
    comm = leidens[1][title2leiden(titles[i])]
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
    comm = leidens[2][title2leiden(titles[i])]
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

    # savefig(plt, "figs/$(df.name[i])-$(titles[i]).html")
end

i = 4
comm = leidens[1][title2leiden(titles[i])]
_colors = [c > 0 && c ≤ length(rgbs) ? rgbs[c] : "gray" for c in comm]
trace = scatter3d(
    ;
    x=Cas[i][:, 1],
    y=Cas[i][:, 2],
    z=Cas[i][:, 3],
    marker=attr(
        size=7,
        color=_colors,
    ),
    line_color="gray",
    # mode="markers",
    name="Leiden 1",
    text=comm,
)

scene_axes=attr(showgrid=false, zeroline=false, showticklabels=false, title="")
fig = plot(trace, Layout(
    template="simple_white",
    scene=attr(
        camera_eye=attr(x=-1, y=+1.5, z=-1),
        xaxis=scene_axes,
        yaxis=scene_axes,
        zaxis=scene_axes,
    ),
))
savefig(fig, "figs/" * df[i,:name] * "-" * titles[i] * "-Leiden1.pdf", width=1000, height=800, scale=2)

# align sequences to compare
seqs = LongAA.(df.sequence)
costmodel = AffineGapScoreModel(BLOSUM62, gap_open=-10, gap_extend=-1)
align47 = pairalign(OverlapAlignment(), seqs[4], seqs[7], costmodel)
align74 = pairalign(OverlapAlignment(), seqs[7], seqs[4], costmodel)

"""
Get xs with gaps mapping from pairwise alignment back to the coordinates of the 
two unaligned sequences.
"""
function align2xs(alignment::PairwiseAlignmentResult)
    align2xs(alignment.aln)
end
function align2xs(alignment::PairwiseAlignment)
    xs1 = Union{Int,Nothing}[]
    xs2 = Union{Int,Nothing}[]
    x1 = 0
    x2 = 0
    for (AA1, AA2) in collect(alignment)
        if AA1 == AA_Gap
            push!(xs1, nothing)
        else
            x1 += 1
            push!(xs1, x1)
        end
        if AA2 == AA_Gap
            push!(xs2, nothing)
        else
            x2 += 1
            push!(xs2, x2)
        end
    end
    return xs1, xs2
end

xsHuman, xsMRSA = align2xs(align74)


fig = [
plot([
    scatter(;
            name="MRSA", # cent1
            y=[isnothing(x) ? nothing : Cas[4][x,5] for x in xsMRSA],
            mode="lines",
            fill="tozeroy",
            line_color="maroon",
    ),
    scatter(;
            name="Human", # cent1
            y=[isnothing(x) ? nothing : Cas[7][x,5] for x in xsHuman],
            mode="lines",
            fill="tozeroy",
            line_color="black",
    ),
    ], Layout(
     yaxis_title="TIF dim 1",
     yaxis_ticklen=2,
    ))
plot([
    scatter(;
            name="MRSA", # cent2
            y=[isnothing(x) ? nothing : Cas[4][x,6] for x in xsMRSA],
            mode="lines",
            fill="tozeroy",
            line_color="maroon",
    ),
    scatter(;
            name="Human", # cent2
            y=[isnothing(x) ? nothing : Cas[7][x,6] for x in xsHuman],
            mode="lines",
            fill="tozeroy",
            line_color="black",
    ),
    ], Layout(
     yaxis_title="TIF dim 2",
     # xaxis_title="Alignment location",
     ))
plot([
    scatter(;
            name="MRSA", # pLDDT
            y=[isnothing(x) ? nothing : Cas[4][x,4] for x in xsMRSA],
            mode="lines",
            fill="tozeroy",
            line_color="maroon",
    ),
    scatter(;
            name="Human", # pLDDT
            y=[isnothing(x) ? nothing : Cas[7][x,4] for x in xsHuman],
            mode="lines",
            fill="tozeroy",
            line_color="black",
    ),
    ], Layout(
     yaxis_title="pLDDT",
     xaxis_title="Alignment location",
     ))
]
# only show region of aligment where both sequences are present
xaxes_attrs=attr(
    range = findall(.!isnothing.(xsMRSA) .& .!isnothing.(xsHuman))[[begin,end]],
    ticklen = 2,
)
relayout!(
    fig,
    yaxis2_ticklen=2,
    yaxis3_ticklen=2,
    xaxis =xaxes_attrs,
    xaxis2=xaxes_attrs,
    xaxis3=xaxes_attrs,
    template="simple_white",
    font_family="Fira Sans",
)

# savefig(fig, "figs/MRSA-centAlign.html")
# savefig(fig, "figs/MRSA-centAlign.pdf", width=850, height=550)


trace = alltraces[4]
push!(trace,
      scatter3d(;
                x=Cas[4][300:450, 1],
                y=Cas[4][300:450, 2],
                z=Cas[4][300:450, 3],
                marker=attr(
                size=5,
                color="maroon",
                ),
                mode="markers+lines",
                name="cent1 difference",
                )
      )
fig = plot(trace, Layout(
    template="simple_white",
    scene_camera_eye=attr(x=-1, y=+1.5, z=-1),
))

savefig(fig, "figs/MRSA-diff3D.html")
relayout!(fig,
          template="simple_white",
          scene_camera_eye=attr(x=-1, y=+1.5, z=-1),
          showlegend=false,
          )
savefig(fig, "figs/MRSA-diff3D.pdf", width=1000, height=800, scale=2)

