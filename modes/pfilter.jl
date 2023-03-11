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

function pfilter(
    eco::String, 
    trial::Int,
    t::Int, 
    domains::Dict{Tuple{String, String}, <:Domain},
    prunecfg::PruneCfg,
)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    jld2file = jldopen(joinpath(ecopath, "$trial.jld2"), "r")
    spids = keys(jld2file["arxiv/1/species"])
    pftags = Dict(
        spid => deserialize(joinpath(ENV["COEVO_DATA_DIR"], eco, "tags", "$spid-$trial.jls"))
        for spid in spids
    )
    fdict = Dict(
        spid => pfilter(jld2file, spid, pftags[spid], t, domains, prunecfg) for spid in spids
    )
    close(jld2file)
    GC.gc()
    EcoStats(eco, trial, t, fdict)
end
