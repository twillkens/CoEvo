using Distributed
@everywhere using Pkg
@everywhere Pkg.activate(".")
@everywhere using Pidfile
@everywhere using CoEvo
@everywhere using JLD2
@everywhere include("fssf.jl")
using StatsBase
using DataFrames


@everywhere function countgeno(eco::String, trial::Int)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    archiver = FSMIndivArchiver()
    jld2path = joinpath(ecopath, "$trial.jld2")
    jld2file = jldopen(jld2path, "r")
    allfssfs = Dict{String, Vector{FSMSpeciesSizeFeatures}}()
    for genkey in keys(jld2file["arxiv"])
        if parse(Int, genkey) % 1000 == 0
            println("$trial-$genkey")
        end
        gengroup = jld2file["arxiv"][genkey]
        allspgroup = gengroup["species"]
        for spid in keys(allspgroup)
            if spid ∉ keys(allfssfs)
                allfssfs[spid] = Vector{FSMSpeciesSizeFeatures}()
            end
            genocounts = Int[]
            mingenocounts = Int[]
            spgroup = allspgroup[spid]
            childrengroup = spgroup["children"]
            for iid in keys(childrengroup)
                childgroup = childrengroup[iid]
                geno = archiver(childgroup["geno"])
                if "mingeno" in keys(childgroup)
                    mingeno = archiver(childgroup["mingeno"])
                else
                    mingeno = minimize(geno)
                end
                push!(genocounts, length(geno.ones) + length(geno.zeros))
                push!(mingenocounts, length(mingeno.ones) + length(mingeno.zeros))
            end
            fssf = FSMSpeciesSizeFeatures(genocounts, mingenocounts)
            push!(allfssfs[spid], fssf)
        end
    end
    close(jld2file)
    allfssfs
end


function make_spfeatdict(
    ecospcounts::Dict{Int, Dict{String, Vector{FSMSpeciesSizeFeatures}}}, 
)
    spfeatdict = Dict{String, Dict{Int, Vector{FSMSpeciesSizeFeatures}}}()
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

function get_featurevecs(spfeatdict::Dict{String, Dict{Int, Vector{FSMSpeciesSizeFeatures}}})
    featurevecs = Dict{String, Vector{Dict{Int, FSMSpeciesSizeFeatures}}}()
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

function get_metafeatures(
    featdict_vecs::Dict{String, Vector{Dict{Int, FSMSpeciesSizeFeatures}}}, 
    field::Symbol = :median
)
    metafeatures = Dict{String, Vector{FSMSpeciesSizeFeatures}}()
    for (spid, featdictvec) in featdict_vecs
        metafeatures[spid] = [
            FSMSpeciesSizeFeatures(collect(values(featdict)), field) 
            for featdict in featdictvec
        ]
    end
    metafeatures
end

function countgeno(eco::String, trials::UnitRange{Int})
    futures = [
        @spawnat :any countgeno(eco, trial) 
        for trial in trials]
    trialfssfs = Dict(
        trial => fetch(future) 
        for (trial, future) in zip(trials, futures)
    )
    spfeatdict = make_spfeatdict(trialfssfs)
    featdict_vecs = get_featurevecs(spfeatdict)
    mfeats = get_metafeatures(featdict_vecs)
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
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    statspath = joinpath(ecopath, "countgeno.jld2")
    statjld = jldopen(statspath, "w")
    statjld["df"] = df
    statjld["mfeats"] = mfeats
    statjld["featdict_vecs"] = featdict_vecs
    close(statjld)
end

# function getcountdata(
#     eco::String, 
#     trange::UnitRange{Int} = 1:20, 
#     genrange::UnitRange{Int} = 1:50_000, 
#     field::Symbol = :median
# )
#     ecopath = joinpath(ENV["COEVO_DATA_DIR"], string(eco))
#     println("1")
#     ecosp = getecosp(ecopath, trange, genrange)
#     println("2")
#     ecospcounts = count_ecosp(ecosp)
#     println("3")
#     spfeatdict = make_spfeatdict(ecospcounts)
#     println("4")
#     featdict_vecs = get_featurevecs(spfeatdict)
#     println("5")
#     mfeats = get_metafeatures(featdict_vecs, field)
#     println("6")
#     dfdict = Dict{String, Vector{Float64}}()
#     for (spid, featvec) in mfeats
#         dfdict["$(spid)_geno_med"] = [feat.genosf.median for feat in featvec]
#         dfdict["$(spid)_geno_upper"] = [feat.genosf.upper_quartile for feat in featvec]
#         dfdict["$(spid)_geno_lower"] = [feat.genosf.lower_quartile for feat in featvec]
#         dfdict["$(spid)_mingeno_med"] = [feat.mingenosf.median for feat in featvec]
#         dfdict["$(spid)_mingeno_upper"] = [feat.mingenosf.upper_quartile for feat in featvec]
#         dfdict["$(spid)_mingeno_lower"] = [feat.mingenosf.lower_quartile for feat in featvec]
# 
#     end
#     df = DataFrame(dfdict)
#     statspath = joinpath(ecopath, "sizestats.jld2")
#     statjld = jldopen(statspath, "w")
#     statjld["df"] = df
#     statjld["mfeats"] = mfeats
#     statjld["featdict_vecs"] = featdict_vecs
#     close(statjld)
# end
# 
# 
# 
# function plotsizes(eco::String)
#     ecopath = joinpath(ENV["COEVO_DATA_DIR"], string(eco))
#     statspath = joinpath(ecopath, "sizestats.jld2")
#     statjld = jldopen(statspath, "r")
#     mfeats = statjld["mfeats"]
#     
#     for (spid, featvec) in mfeats
#         println(spid)
#         for feat in featvec
#             println(feat.genosf)
#             println(feat.mingenosf)
#         end
#     end
# 
# 
# end




# 
# 
# function getecosp(
#     ecopath::String, trange::UnitRange{Int} = 1:20, genrange::UnitRange{Int} = 1:10_000
# )
#     futures = [
#         @spawnat :any unfreeze(ecopath, trial, false, genrange) 
#         for trial in trange
#     ]
#     Dict(
#         trial => fetch(future) 
#         for (trial, future) in zip(trange, futures)
#     )
# end
# 
# 
# function sizestats(spvec::Vector{<:Dict{Symbol, <:Species}})
#     spsizedict = Dict{Symbol, Vector{FSMSpeciesSizeFeatures}}()
#     for spdict in spvec
#         for (spid, sp) in spdict
#             feat = FSMSpeciesSizeFeatures(sp)
#             if spid in keys(spsizedict)
#                 push!(spsizedict[spid], feat)
#             else
#                 spsizedict[spid] = [feat]
#             end
#         end
#     end
#     spsizedict
# end
# 
# function count_ecosp(ecosp::Dict{Int, <:Vector{<:Dict{Symbol, <:Species}}})
# #function count_ecosp(ecosp::Dict{Int, Vector{T}}, domingeno::Bool) where T
#     Dict(
#         trial => sizestats(spvec) 
#         for (trial, spvec) in ecosp
#     )
# end
# 