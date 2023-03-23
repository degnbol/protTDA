#!/usr/bin/env julia
using Arrow
using CSV, DataFrames
df_acc = DataFrame(acc=readlines(stdin))
df = Arrow.Table("acc2path.arrow") |> DataFrame
df_res = innerjoin(df_acc, df; on=:acc)
CSV.write(stdout, df_res; delim='\t')
println(stderr, "$(nrow(df_res))/$(nrow(df_acc)) accs found")
