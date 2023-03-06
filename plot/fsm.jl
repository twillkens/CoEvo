using Plots
using JLD2
using StatsBase
using CoEvo
using DataFrames

function countsizes(eco::String, trial::Int)
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


function getecosp(
    ecopath::String, trange::UnitRange{Int} = 1:20, genrange::UnitRange{Int} = 1:10_000
)
    Dict(
        trial => unfreeze(joinpath(ecopath, "$trial.jld2"), false, genrange) 
        for trial in trange
    )
end

struct FSMSpeciesSizeFeatures
    genosf::StatFeatures
    mingenosf::StatFeatures
end

function FSMSpeciesSizeFeatures(sp::Species, domingeno::Bool)
    allsizes = Vector{Int}()
    allminsizes = Vector{Int}()
    for child in values(sp.children)
        geno = child.geno
        push!(allsizes, length(geno.ones) + length(geno.zeros))
        if domingeno
            mingeno = minimize(geno)
            push!(allminsizes, length(mingeno.ones) + length(mingeno.zeros))
        end
    end
    FSMSpeciesSizeFeatures(StatFeatures(allsizes), StatFeatures(allminsizes))
end

function FSMSpeciesSizeFeatures(v::Vector{FSMSpeciesSizeFeatures}, field::Symbol)
    FSMSpeciesSizeFeatures(
        StatFeatures([v.genosf for v in v], field),
        StatFeatures([v.mingenosf for v in v], field)
    )
end

function sizestats(spvec::Vector{<:Dict{Symbol, <:Species}}, domingeno::Bool)
    spsizedict = Dict{Symbol, Vector{FSMSpeciesSizeFeatures}}()
    for spdict in spvec
        for (spid, sp) in spdict
            feat = FSMSpeciesSizeFeatures(sp, domingeno)
            if spid in keys(spsizedict)
                push!(spsizedict[spid], feat)
            else
                spsizedict[spid] = [feat]
            end
        end
    end
    spsizedict
end

function count_ecosp(ecosp::Dict{Int, <:Vector{<:Dict{Symbol, <:Species}}}, domingeno::Bool)
#function count_ecosp(ecosp::Dict{Int, Vector{T}}, domingeno::Bool) where T
    Dict(
        trial => sizestats(spvec, domingeno) 
        for (trial, spvec) in ecosp
    )
end

function make_spfeatdict(
    ecospcounts::Dict{Int, Dict{Symbol, Vector{FSMSpeciesSizeFeatures}}}, 
)
    spfeatdict = Dict{Symbol, Dict{Int, Vector{FSMSpeciesSizeFeatures}}}()
    for (trial, spdict) in ecospcounts
        for (spid, featvec) in spdict
            if spid in keys(spfeatdict)
                spfeatdict[spid][trial] = featvec
            else
                spfeatdict[spid] = Dict(trial => featvec)
            end
        end
    end
    spfeatdict
end

function get_featurevecs(spfeatdict::Dict{Symbol, Dict{Int, Vector{FSMSpeciesSizeFeatures}}})
    featurevecs = Dict{Symbol, Vector{Dict{Int, FSMSpeciesSizeFeatures}}}()
    for (spid, trialdict) in spfeatdict
        featurevecs[spid] = Dict{Int, FSMSpeciesSizeFeatures}[]
        for (trial, featvec) in trialdict
            for (i, feat) in enumerate(featvec)
                if i > length(featurevecs[spid])
                    push!(featurevecs[spid], Dict(trial => feat))
                else
                    featurevecs[spid][i][trial] = feat
                end
            end
        end
    end
    featurevecs
end

function getcountdata(
    eco::String, 
    trange::UnitRange{Int} = 1:20, 
    genrange::UnitRange{Int} = 1:50_000, 
    domingeno::Bool = false,
    field::Symbol = :median
)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], string(eco))
    println("1")
    ecosp = getecosp(ecopath, trange, genrange)
    println("2")
    ecospcounts = count_ecosp(ecosp, domingeno)
    println("3")
    spfeatdict = make_spfeatdict(ecospcounts)
    println("4")
    featdict_vecs = get_featurevecs(spfeatdict)
    println("5")
    mfeats = get_metafeatures(featdict_vecs, field)
    println("6")
    dfdict = Dict{String, Vector{Float64}}()
    for (spid, featvec) in mfeats
        dfdict["$(spid)_geno_med"] = [feat.genosf.median for feat in featvec]
        dfdict["$(spid)_geno_upper"] = [feat.genosf.upper_quartile for feat in featvec]
        dfdict["$(spid)_geno_lower"] = [feat.genosf.lower_quartile for feat in featvec]
        dfdict["$(spid)_mingeno_med"] = [feat.mingenosf.median for feat in featvec]
        dfdict["$(spid)_mingeno_upper"] = [feat.mingenosf.upper_quartile for feat in featvec]
        dfdict["$(spid)_mingeno_lower"] = [feat.mingenosf.lower_quartile for feat in featvec]

    end
    df = DataFrame(dfdict)
    statspath = joinpath(ecopath, "sizestats.jld2")
    statjld = jldopen(statspath, "w")
    statjld["df"] = df
    statjld["mfeats"] = mfeats
    statjld["featdict_vecs"] = featdict_vecs
    close(statjld)
end

function get_metafeatures(
    featdict_vecs::Dict{Symbol, Vector{Dict{Int, FSMSpeciesSizeFeatures}}}, 
    field::Symbol = :median
)
    metafeatures = Dict{Symbol, Vector{FSMSpeciesSizeFeatures}}()
    for (spid, featdictvec) in featdict_vecs
        metafeatures[spid] = [
            FSMSpeciesSizeFeatures(collect(values(featdict)), field) 
            for featdict in featdictvec
        ]
    end
    metafeatures
end


function plotsizes(eco::String)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], string(eco))
    statspath = joinpath(ecopath, "sizestats.jld2")
    statjld = jldopen(statspath, "r")
    mfeats = statjld["mfeats"]
    for (spid, featvec) in mfeats
        println(spid)
        for feat in featvec
            println(feat.genosf)
            println(feat.mingenosf)
        end
    end


end



