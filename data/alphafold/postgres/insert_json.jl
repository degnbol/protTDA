#!/usr/bin/env julia
using Arrow
using DataFrames
using LibPQ

ROOT = `git root` |> readchomp
cd("$ROOT/data/alphafold")

# @time dt = Arrow.Table("prot.accession2taxid.arrow")
#
# @time userows = [acc[3] != '_' for acc in dt.accession];
#
# df = DataFrame(dt);
# rename!(df, :accession => :acc, :taxid => :tax);
#
# @time df = df[userows, [:acc, :tax]];
#
# nrow(df) |> println
# @time unique!(df);
# nrow(df) |> println
#
# df.acc |> unique |> length |> println

@time dt2 = Arrow.Table("acc2path.arrow")
df2 = DataFrame(dt2)[!, [:acc, :path]];

# @time df3 = innerjoin(df2, df; on=:acc);

conn = LibPQ.Connection("dbname=protTDA")

"""
Insert a DataFrame into a postgres database with connection "conn".
"""
function pqinsert(conn, table::String, df::DataFrame)
    query = LibPQ.CopyIn("COPY $table FROM STDIN (FORMAT CSV);", join.(eachrow(df), ',') .* '\n')
    execute(conn, query)
end

# took 46 minutes
pqinsert(conn, "json", df2)

close(conn)

