#!/usr/bin/env julia
using Arrow, CodecLz4
using DataFrames
using Chain: @chain

@time df_clust = open("uniclust30.arrow.lz4") do io
    @chain io read transcode(LZ4FrameDecompressor, _) Arrow.Table DataFrame disallowmissing
end
rename!(df_clust, :column_1 => :rep, :column_2 => :acc)

@time df_rep = combine(groupby(df_clust, :rep), nrow => :nMembers)
singletons = df_rep.rep[df_rep.nMembers .== 1]
df_multi = df_rep[df_rep.nMembers .> 1, :]
reps = df_multi.rep

df_acc2path = Arrow.Table("../alphafold/acc2path.arrow") |> DataFrame
df_multi2path = innerjoin(df_multi, df_acc2path; on= :rep => :acc)

Arrow.write("uniclust30_multi2path.arrow", df_multi2path; compress=:lz4)

# largest cluster has 74924 members
sort!(df_multi2path, :nMembers)

using Plots
plt = histogram(df_multi2path.nMembers; xaxis=:log, yaxis=:log, legend=false);
savefig(plt, "hist_nMembers.pdf")


