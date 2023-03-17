#!/usr/bin/env zsh
cargo install csv2arrow
wget https://ftp.ebi.ac.uk/pub/databases/alphafold/accession_ids.csv
# -m 2 is max rows to use to detect schema. Schema is simple and it otherwise 
# would use the whole file, so this makes the entire difference of speed.
csv2arrow -m 2 --header false accession_ids.{csv,arrow}

# In julia realising that all have offset 1
# using Arrow, DataFrames
# dt_offset = Arrow.Table("accession_ids.arrow")
# df_offset = DataFrame(dt_offset)[!, [:column_1, :column_2]]
# rename!(df_offset, :column_1 => :acc, :column_2 => :offset)
# df_of = innerjoin(DataFrame(acc=accs), df_offset; on=:acc)
# disallowmissing!(df_of)
# all(dt_offset.column_2 .== 1)
