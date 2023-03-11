export dotags!

function tfilter!(
    jld2file::JLD2.JLDFile, 
    gen::Int,
    spid::String,
    pftags::Vector{Vector{FilterTag}},
    tagdict::Dict{String, Int}, 
)
    childrengroup = jld2file["arxiv/$gen/species/$spid/children"]
    new_tagdict = Dict{String, Int}()
    ftags = Vector{FilterTag}()
    for (tag, iid) in enumerate(keys(childrengroup))
        new_tagdict[iid] = tag
        pid = first(childrengroup[iid]["pids"])
        prevtag = tagdict[string(pid)]
        ftag = FilterTag(gen, spid, iid, prevtag, tag)
        push!(ftags, ftag)
    end
    nexttags = Set([ftag.prevtag for ftag in ftags])
    filter!(ftag -> ftag.currtag in nexttags, pftags[end])
    push!(pftags, ftags)
    new_tagdict
end

function tpass!(
    jld2file::JLD2.JLDFile, 
    gen::Int,
    spid::String,
    tagdict::Dict{String, Int},
)
    childrengroup = jld2file["arxiv/$gen/species/$spid/children"]
    Dict(
        iid => tagdict[string(first(childrengroup[iid]["pids"]))] 
        for iid in keys(childrengroup)
    )
end

function ptags!(
    jld2file::JLD2.JLDFile, 
    eco::String,
    trial::Int,
    spid::String,
    t::Int, 
    until::Int = typemax(Int)
)
    tagdict, pftags = init_pftags(jld2file, spid)
    for gen in 2:length(keys(jld2file["arxiv"]))
        if gen > until
            break
        end
        if gen % 1000 == 0
            println("$(myid() - 1)-$spid-$gen")
        end
        tagdict = gen % t == 0 ? 
            tfilter!(jld2file, gen, spid, pftags, tagdict) : 
            tpass!(jld2file, gen, spid, tagdict)
    end
    pop!(pftags)
    mkpath(joinpath(ENV["COEVO_DATA_DIR"], eco, "tags"))
    tagspath = joinpath(ENV["COEVO_DATA_DIR"], eco, "tags", "$spid-$trial.jls")
    serialize(tagspath, pftags)
end

function ptags!(
    eco::String, 
    trial::Int,
    t::Int, 
    until::Int = typemax(Int)
)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    jld2file = jldopen(joinpath(ecopath, "$trial.jld2"), "r")
    spids = keys(jld2file["arxiv/1/species"])
    [ptags!(jld2file, eco, trial, spid, t, until) for spid in spids]
    close(jld2file)
end

function dotags!(
    eco::String, 
    trials::UnitRange{Int} = 1:20,
    t::Int = 50,
    until::Int = 50_000
)
    futures = [
        @spawnat :any ptags!(eco, trial, t, until) 
        for trial in trials
    ]
    [fetch(future) for future in futures]
end
