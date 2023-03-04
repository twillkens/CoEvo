using Plots
using JLD2
using StatsBase

function countsize(eco::String, trial::Int)
    dpath = ENV["COEVO_DATA_DIR"]
    path = joinpath(dpath, string(eco), "$trial.jld2")
    jld = jldopen(path, "r")
    arxiv = jld["arxiv"]
    spawners = jld["spawners"]

    spsizedict = Dict{String, Vector{Float64}}()
    for genkey in keys(arxiv)
        gengroup = arxiv[genkey]
        allspgroup = gengroup["species"]
        for spid in keys(allspgroup)
            spgroup = allspgroup[spid]
            children_group = spgroup["children"]
            allsizes = Int[]
            allminsizes = Int[]
            for iid in keys(children_group)
                childgroup = children_group[iid]
                geno = spawners[Symbol(spid)].archiver(childgroup["geno"])
                mingeno = minimize(geno)
                push!(allsizes, length(geno.ones) + length(geno.zeros))
                push!(allminsizes, length(mingeno.ones) + length(mingeno.zeros))
            end
            # add to spsizedict the mean size of the population
            if spid in keys(spsizedict)
                push!(spsizedict[spid], mean(allsizes))
                push!(spsizedict["$spid-min"], mean(allminsizes))
            else
                spsizedict[spid] = [mean(allsizes)]
                spsizedict["$spid-min"] = [mean(allminsizes)]
            end
        end
    end
    close(jld)
    return spsizedict
end