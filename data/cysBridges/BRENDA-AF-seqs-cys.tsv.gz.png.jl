#!/usr/bin/env julia
using Statistics
using Gadfly
using Gadfly: RGB, RGBA, fillopacity
using Gadfly: context, text, compose
using Compose # hleft and other HAlignment
using Printf
ROOT = `git root` |> readchomp
include("$ROOT/src/util/dataframes.jl")

function annotation(x, y, s, args...)
    compose(context(), text(x, y, s, args...)) |> Guide.annotation
end

DataFrames.dropmissing(v::Vector) = v[.!ismissing.(v)]

df = loadtsv("BRENDA-AF-seqs-cys.tsv.gz")
df = df[df.nCys .!= -1, :]
df.fracCys = df.nCys ./ length.(df.AA)

set_default_plot_size(30cm, 20cm)

plts = [Plot() Plot() Plot()
        Plot() Plot() Plot()]

for (i,tempMin,tempMax) ∈ [(1, :tempOptimMin, :tempOptimMax), (2, :tempMin, :tempMax)]
    df_pt = df[.!ismissing.(df[!,tempMin]) .&& (df[!,tempMin] .== df[!,tempMax]), :]
    for (j,cys) in enumerate([:nCys, :nCysClose, :fracCys])
        segments = layer(df, Geom.segment, y=tempMin, yend=tempMax, x=cys, xend=cys,
                         style(line_width=2pt, default_color=RGBA(.1,.1,.9,.1)))
        points = layer(df_pt, Geom.point, y=tempMin, x=cys,
                       style(point_size=1pt, highlight_width=0pt, default_color=RGB(.1,.1,.9)))
        toCor = vcat((Matrix(dropmissing(df[!, [tempMin, cys]])) for temp in [tempMin, tempMax])...)
        corr = cor(toCor[:, 1], toCor[:, 2])
        lab = annotation(maximum(df[!,cys]), maximum(dropmissing(df[!,tempMax])),
                         @sprintf("cor=%.3f", corr),
                         hright)
        plts[i,j] = plot(segments, points, lab, Guide.ylabel(String(tempMin)[1:end-3]))
    end
end

plt = gridstack(plts)
import Cairo, Fontconfig
draw(PNG("BRENDA-AF-seqs-cys.tsv.gz.png", dpi=250), plt)

