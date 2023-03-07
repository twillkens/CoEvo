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

@everywhere struct FilterTag
    gen::Int
    spid::String
    iid::String
    prevtag::Int
    currtag::Int
end


@everywhere function pfilter(
    jld2file::JLD2.JLDFile, spid::String, t::Int, until::Int = typemax(Int), closefile = true
)
    # archiver = FSMIndivArchiver()
    tagdict = Dict{String, Int}()

    childrengroup = jld2file["arxiv/1/species/$spid/children"]
    ftags = Vector{FilterTag}()
    for (tag, iid) in enumerate(keys(childrengroup))
        tagdict[iid] = tag
        prevtag = -1
        ftag = FilterTag(1, spid, iid, prevtag, tag)
        push!(ftags, ftag)
    end
    pfiltered = [ftags]


    for gen in 2:length(keys(jld2file["arxiv"]))
        if gen > until
            break
        end
        if gen % 1000 == 0
            println("$(myid() - 1)-$spid-$gen")
        end
        childrengroup = jld2file["arxiv/$gen/species/$spid/children"]
        new_tagdict = Dict{String, Int}()
        if gen % t == 0
            ftags = Vector{FilterTag}()
            for (tag, iid) in enumerate(keys(childrengroup))
                #jldpath = "arxiv/$gen/species/$spid/children/$iid"
                #indiv = archiver(spid, iid, childrengroup[iid])
                new_tagdict[iid] = tag
                pid = first(childrengroup[iid]["pids"])
                prevtag = tagdict[string(pid)]
                ftag = FilterTag(gen, spid, iid, prevtag, tag)
                push!(ftags, ftag)
            end
            nexttags = Set([ftag.prevtag for ftag in ftags])
            filter!(ftag -> ftag.currtag in nexttags, pfiltered[end])
            push!(pfiltered, ftags)
        else
            for iid in keys(childrengroup)
                pid = first(childrengroup[iid]["pids"])
                new_tagdict[iid] = tagdict[string(pid)]
            end
        end
        tagdict = new_tagdict
    end
    pop!(pfiltered)
    if closefile
        close(jld2file)
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
    jld2path = joinpath(ecopath, "pfilter-tags.jld2")
    jld2file = jldopen(jld2path, "w")
    for i in eachindex(allspfiltered)
        jld2file["$i"] = allspfiltered[i]
    end
    close(jld2file)
end


function getindivs(jld2file::JLD2.JLDFile, allspftags::Dict{String, Vector{Vector{FilterTag}}})
    archiver = FSMIndivArchiver()
    allspindivs = Dict{String, Vector{Vector{FilterIndiv}}}()
    for (spid, allftags) in allspftags
        allspindivs[spid] = Vector{Vector{FilterIndiv}}()
        for ftags in allftags
            indivs = Vector{FilterIndiv}()
            for ftag in ftags
                igroup = jld2file["arxiv/$(ftag.gen)/species/$(ftag.spid)/children/$(ftag.iid)"]
                indiv = archiver(ftag.spid, ftag.iid, igroup)
                push!(indivs, FilterIndiv(indiv, ftag.prevtag, ftag.currtag))
            end
            push!(allspindivs[spid], indivs)
        end
    end
    close(jld2file)
    allspindivs
end

function getindivs(eco::String, trial::String, allspftags::Dict{String, Vector{Vector{FilterTag}}})
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    jld2path = joinpath(ecopath, "$trial.jld2")
    jld2file = jldopen(jld2path, "r")
    getindivs(jld2file, allspftags)
end

function getindivs(eco::String, trial::String)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    tags_jld2path = joinpath(ecopath, "pfilter-tags.jld2")
    tags_jld2file = jldopen(tags_jld2path, "r")
    allspftags = tags_jld2file["$trial"]
    getindivs(eco, trial, allspftags)
end

function writeindivs(eco::String)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    tags_jld2file = jldopen(joinpath(ecopath, "pfilter-tags.jld2"), "r")
    indivs_jld2path = joinpath(ecopath, "pfilter-indivs.jld2")

    for trial in keys(tags_jld2file)
        println(trial)
        allspftags = tags_jld2file[trial]
        allspindivs = getindivs(eco, trial, allspftags)
        indiv_jld2file = jldopen(indivs_jld2path, "a")
        for (spid, spindivs) in allspindivs
            indiv_jld2file["$spid/$trial"] = spindivs
        end
        close(indiv_jld2file)
    end
end
