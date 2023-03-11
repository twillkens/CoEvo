export pfilter

function pfilter(
    jld2file::JLD2.JLDFile,
    spid::String,
    pftags::Vector{Vector{FilterTag}},
    t::Int,
    domains::Dict{Tuple{String, String}, <:Domain},
    prunecfg::PruneCfg,
)
    allfindivs = Vector{Vector{FilterIndiv}}()
    for (gen, ftags) in enumerate(pftags)
        gen = gen == 1 ? 1 : (gen - 1) * t
        prunes = prunecfg(jld2file, ftags)
        genphenodict = get_genphenodict(jld2file, gen, spid)
        fight!(spid, prunes, genphenodict, domains)
        push!(allfindivs, [FilterIndiv(prune, genphenodict, domains) for prune in prunes])
        if gen % 1_000 == 0
            println("filtering $spid at gen $gen")
            GC.gc()
        end
    end
    GC.gc()
    #FilterResults(spid, t, nothing, SpeciesStats(spid, allfindivs))
    FilterResults(spid, t, allfindivs, SpeciesStats(spid, allfindivs))
end

# filter to get the tags of the persistent individuals
function init_pftags(jld2file::JLD2.JLDFile, spid::String)
    tagdict = Dict{String, Int}()
    childrengroup = jld2file["arxiv/1/species/$spid/children"]
    ftags = Vector{FilterTag}()
    for (tag, iid) in enumerate(keys(childrengroup))
        tagdict[iid] = tag
        prevtag = -1
        ftag = FilterTag(1, spid, iid, prevtag, tag)
        push!(ftags, ftag)
    end
    pftags = [ftags]
    tagdict, pftags
end

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

function pfilter(
    jld2file::JLD2.JLDFile, 
    eco::String,
    spid::String,
    t::Int, 
    domains::Dict{Tuple{String, String}, <:Domain},
    prunecfg::PruneCfg,
    until::Int = typemax(Int)
)
    tagspath = joinpath(ENV["COEVO_DATA_DIR"], eco, "tags.jls")
    if isfile(tagspath)
        pftags = deserialize(tagspath)
        return pfilter(jld2file, spid, pftags, t, domains, prunecfg)
    end
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
    serialize(tagspath, pftags)
    GC.gc()
    pfilter(jld2file, spid, pftags, t, domains, prunecfg)
end

function pfilter(
    eco::String, 
    trial::Int,
    t::Int, 
    domains::Dict{Tuple{String, String}, <:Domain},
    prunecfg::PruneCfg,
    until::Int = typemax(Int)
)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    jld2file = jldopen(joinpath(ecopath, "$trial.jld2"), "r")
    spids = keys(jld2file["arxiv/1/species"])
    fdict = Dict(
        spid => pfilter(jld2file, eco, spid, t, domains, prunecfg, until) for spid in spids
    )
    close(jld2file)
    GC.gc()
    EcoStats(eco, trial, t, fdict)
end