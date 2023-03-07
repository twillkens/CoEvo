using Distributed
@everywhere using Pkg
@everywhere Pkg.activate(".")
@everywhere using Pidfile
@everywhere using CoEvo
@everywhere using JLD2
@everywhere include("fssf.jl")
using StatsBase
using DataFrames
@everywhere using DataStructures

@everywhere struct FilterIndiv{I <: FSMIndiv}
    indiv::I
    prevtag::Int
    currtag::Int
end


@everywhere function pfilter(
    jld2file::JLD2.JLDFile, spid::String, t::Int, until::Int = typemax(Int), closefile = true
)
    archiver = FSMIndivArchiver()
    tagdict = Dict{String, Int}()
    pfiltered = SortedDict{Int, Vector{FilterIndiv}}()

    childrengroup = jld2file["arxiv/1/species/$spid/children"]
    findivs = Vector{FilterIndiv}()
    for (tag, iid) in enumerate(keys(childrengroup))
        indiv = archiver(spid, iid, childrengroup[iid])
        tagdict[iid] = tag
        prevtag = -1
        findiv = FilterIndiv(indiv, prevtag, tag)
        push!(findivs, findiv)
    end
    pfiltered[1] = findivs


    for genkey in 2:length(keys(jld2file["arxiv"]))
        if genkey > until
            break
        end
        if genkey % 1000 == 0
            println("$spid-$genkey")
        end
        childrengroup = jld2file["arxiv/$genkey/species/$spid/children"]
        new_tagdict = Dict{String, Int}()
        if genkey % t == 0
            findivs = Vector{FilterIndiv}()
            for (tag, iid) in enumerate(keys(childrengroup))
                indiv = archiver(spid, iid, childrengroup[iid])
                new_tagdict[iid] = tag
                prevtag = tagdict[string(first(indiv.pids))]
                findiv = FilterIndiv(indiv, prevtag, tag)
                push!(findivs, findiv)
            end
            pfiltered[genkey] = findivs
        else
            for iid in keys(childrengroup)
                pid = first(childrengroup[iid]["pids"])
                new_tagdict[iid] = tagdict[string(pid)]
            end
        end
        tagdict = new_tagdict
    end
    if closefile
        close(jld2file)
    end
    vecs = collect(values(pfiltered))
    for (idx, v) in enumerate(vecs)
        if idx == length(vecs)
            break
        end
        nextv = vecs[idx + 1]
        nexttags = Set([findiv.prevtag for findiv in nextv])
        filter!(findiv -> findiv.currtag in nexttags, v)
    end
    pfiltered
end

@everywhere function pfilter(
    eco::String, trial::Int, spid::String, t::Int, until::Int = typemax(Int)
)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    jld2path = joinpath(ecopath, "$trial.jld2")
    jld2file = jldopen(jld2path, "r")
    println(keys(jld2file["arxiv/1/species"]))
    pfilter(jld2file, spid, t, until)
end


@everywhere function pfilter(eco::String, trial::Int, t::Int, until::Int = typemax(Int))
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    jld2path = joinpath(ecopath, "$trial.jld2")
    jld2file = jldopen(jld2path, "r")
    spids = keys(jld2file["arxiv/1/species"])
    println("spids: $spids")
    spfiltered = Dict(spid => pfilter(jld2file, spid, t, until, false) for spid in spids)
    close(jld2file)
    spfiltered
end

function pfilter(eco::String, trials::UnitRange{Int}, t::Int, until::Int = typemax(Int))
    futures = [
        @spawnat :any pfilter(eco, trial, t, until) 
        for trial in trials
    ]
    [fetch(future) for future in futures]
end

function writepfilter(eco::String, trial::Int, t::Int, until::Int = typemax(Int))
    spfiltered = pfilter(eco, trial, t, until)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    jld2path = joinpath(ecopath, "pfilter-trial-$t.jld2")
    jld2file = jldopen(jld2path, "w")
    for (spid, spfilter) in spfiltered
        jld2file[spid] = spfilter
    end
    close(jld2file)
end

function writepfilter(eco::String, trials::UnitRange{Int}, t::Int, until::Int = typemax(Int))
    allspfiltered = pfilter(eco, trials, t, until)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    jld2path = joinpath(ecopath, "pfilter.jld2")
    jld2file = jldopen(jld2path, "w")
    for i in eachindex(allspfiltered)
        jld2file["$i"] = allspfiltered[i]
    end
    close(jld2file)
end