#!/usr/bin/env julia
using CSV, DataFrames
using GZip
using Statistics: mean, cor
using Chain: @chain

ROOT = `git root` |> readchomp
cd("$ROOT/data/alphafold/vis/")

df_names = CSV.read("../taxon/names.tsv.gz", DataFrame; delim='\t', quoted=false)

dfn = CSV.read("../postgres/treeNode.tsv.gz", DataFrame; delim='\t')
dfe = CSV.read("../postgres/treeEdge.tsv.gz", DataFrame; delim='\t')
dfnpp = CSV.read("../postgres/treeNode_perProt.tsv.gz", DataFrame; delim='\t')
dfepp = CSV.read("../postgres/treeEdge_perProt.tsv.gz", DataFrame; delim='\t')
dfnd = CSV.read("../postgres/treeNode_domain.tsv.gz", DataFrame; delim='\t')
dfed = CSV.read("../postgres/treeEdge_domain.tsv.gz", DataFrame; delim='\t')

dfN = innerjoin(dfn, dfnpp; on=:tax, renamecols= "" => "_pp")
@assert all(dfN.rank .== dfN.rank_pp)
select!(dfN, Not(:rank_pp))
mean(dfN.proteins .== dfN.proteins_pp) |> println

# add labels
rename!(dfN, :tax => :id)
leftjoin!(dfN, df_names[df_names.type .== "scientific name", Not(:type)]; on= :id => :tax)
rename!(dfN, :name => :label)

# make domain node and edge lists wider format
dfnD = innerjoin(
          dfnd[dfnd.by_protein .== "f", Not(:by_protein)],
          rename(n -> n*"_pp", dfnd[dfnd.by_protein .== "t", Not(:by_protein)]);
          on= :domain => :domain_pp)
dfeD = innerjoin(
          dfed[dfed.by_protein .== "f", Not(:by_protein)],
          rename(n -> n*"_pp", dfed[dfed.by_protein .== "t", Not(:by_protein)]);
          on= [:parent => :parent_pp, :child => :child_pp])

# add root node and domain node labels
dfnD.id .= dfnD.domain
@assert dfnD.id == split("ABEV", "") # assert order
dfnD.label = ["Archaea", "Bacteria", "Eukaryote", "Virus"]
append!(dfnD, DataFrame(id="O", domain="O", label="Origin", proteins=sum(dfnD.proteins)); cols=:subset)
append!(dfeD, DataFrame(parent="O", child=split("ABEV", "")); cols=:subset)

# append domain node list
dfN.type .= "tax"
dfnD.type .= "domain"
dfnD.rank .= "domain"
append!(dfN, dfnD; cols=:subset)

# remove columns that takes up unnecessary space
binCols = names(dfN)[match.(r"avg_nrep[12]_[bft][0-9].*", names(dfN)) .!== nothing]
select!(dfN, Not(binCols))

# append domain edge list
dfE = innerjoin(dfe, dfepp; on=[:parent, :child], renamecols= "" => "_pp")
append!(dfE, dfeD; promote=true)

# calc corr on vector columns

# list edge table column names that doesn't contain scalars
vecCells = ["$(n)_nrep$(i)_b$pp" for n in "cp" for i in 1:2 for pp in ["", "_pp"]]

# parse text
for vecCell in vecCells
    # fake bins data for root aka. origin
    dfE[dfE.parent .== "O", vecCell] .= join(["0.1" for b in 1:11], ',')
    dfE[!, vecCell] .= @chain dfE[!, vecCell] strip.(Ref(['{','}'])) split.(',')
    dfE[!, vecCell] .= [parse.(Float64, vs) for vs in dfE[!, vecCell]]
end

vecCells_c = vecCells[startswith.(vecCells, 'c')]
vecCells_p = vecCells[startswith.(vecCells, 'p')]

dfE.cor_nrep1    .= cor.(dfE.c_nrep1_b, dfE.p_nrep1_b)
dfE.cor_nrep2    .= cor.(dfE.c_nrep2_b, dfE.p_nrep2_b)
dfE.cor_nrep1_pp .= cor.(dfE.c_nrep1_b_pp, dfE.p_nrep1_b_pp)
dfE.cor_nrep2_pp .= cor.(dfE.c_nrep2_b_pp, dfE.p_nrep2_b_pp)

"""
another correlation is to the values from siblings rather than parent.
Otherwise higher correlation values are given for children that simply make up a 
larger fraction of the proteins for a given parent.
"""
function siblings(parent, child, col::Symbol)
    mean(reduce(hcat, dfE[(dfE.parent .== parent).&&(dfE.child .!= child), col]; init=zeros(11)); dims=2) |> vec
end
"Weighted average per protein."
function siblings_pp(parent, child, col::Symbol)
    sibs = dfE[(dfE.parent .== parent).&&(dfE.child .!= child), [:child, col]]
    sibs.proteins = innerjoin(dfN, sibs; on= :id => :child).proteins
    sum(reduce(hcat, sibs[!, col]; init=zeros(11)) .* sibs.proteins'; dims=2) ./ sum(sibs.proteins) |> vec
end

# dfE.cor_nrep1_sib    .= cor.(dfE.c_nrep1_b, siblings.(dfE.parent, dfE.child, :c_nrep1_b))
# dfE.cor_nrep2_sib    .= cor.(dfE.c_nrep2_b, siblings.(dfE.parent, dfE.child, :c_nrep2_b))
# dfE.cor_nrep1_pp_sib .= cor.(dfE.c_nrep1_b_pp, siblings_pp.(dfE.parent, dfE.child, :c_nrep1_b_pp))
# dfE.cor_nrep2_pp_sib .= cor.(dfE.c_nrep2_b_pp, siblings_pp.(dfE.parent, dfE.child, :c_nrep2_b_pp))

# NOTE: takes too long. Instead of many look ups, do a cross thing to get all 
# combinations of parents and child without the specific child.
# It might also be ok to do it the normal way, since if we show a large child 
# that takes up most of a parent circle it makes sense that it often should be 
# highly correlated with the parent since they are visually similar. Looking at 
# the plot the motivation for the sibling version seems diminished when you 
# notice there are small children with both high and large correlation.

select!(dfE, Not(vecCells))

# ready for visualisation
CSV.write("taxNodes.tsv.gz", dfN; delim='\t', compress=true)
CSV.write("taxEdges.tsv.gz", dfE; delim='\t', compress=true)
# filtered version for quick testing
CSV.write("taxNodes_noSpecies.tsv.gz", dfN[dfN.rank .!= "species", :]; delim='\t', compress=true)
dfE_noSpecies = innerjoin(dfE, dfN[dfN.rank .!= "species", [:id]]; on= :child => :id)
CSV.write("taxEdges_noSpecies.tsv.gz", dfE_noSpecies; delim='\t', compress=true)


