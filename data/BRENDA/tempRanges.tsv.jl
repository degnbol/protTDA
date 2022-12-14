#!/usr/bin/env julia
using JSON
using DataFrames
using CSV

brenda = JSON.parsefile("brenda_2022_2.json")


function get_brenda_ranges(key::String="temperature_optimum")
    accessions = String[]
    tempMins = Float64[]
    tempMaxs = Float64[]

    for EC in values(brenda["data"])
        haskey(EC, "proteins") || continue
        if haskey(EC, key)
            for measure in EC[key]
                if haskey(measure, "num_value")
                    tempMin, tempMax = measure["num_value"], measure["num_value"]
                elseif haskey(measure, "min_value") && haskey(measure, "max_value")
                    tempMin, tempMax = measure["min_value"], measure["max_value"]
                else
                    continue
                end
                        
                if haskey(measure, "proteins")
                    for protein in measure["proteins"]
                        # only, since there is just uniprot as source.
                        for accession in only(EC["proteins"][protein])["accessions"]
                            push!(accessions, accession)
                            push!(tempMins, tempMin)
                            push!(tempMaxs, tempMax)
                        end
                    end
                end
            end
        end
    end
    
    accessions, tempMins, tempMaxs
end

accessions, tempMins, tempMaxs = get_brenda_ranges()
df_optim = DataFrame(accession=accessions, tempOptimMin=tempMins, tempOptimMax=tempMaxs)
accessions, tempMins, tempMaxs = get_brenda_ranges("temperature_range")
df_range = DataFrame(accession=accessions, tempMin=tempMins, tempMax=tempMaxs)

df = outerjoin(df_optim, df_range; on="accession")


