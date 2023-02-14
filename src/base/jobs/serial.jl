export PhenoJob, SerialPhenoJobConfig, ParallelPhenoJobConfig
export perform

struct PhenoJob{R <: Recipe, P <: Phenotype, O <: Order} <: Job
    odict::Dict{Symbol, O}
    phenodict::Dict{Symbol, Dict{UInt32, P}}
    recipes::Vector{R}
end

function perform(job::Job)
    mixes = getmixes(job)
    [stir(mix) for mix in mixes]
end

function perform(jobs::Set{<:Job})
    futures = [remotecall(perform, i, job) for (i, job) in enumerate(jobs)]
    outcomes = [fetch(f) for f in futures]
    Iterators.flatten(outcomes)
end

function divvy(recipes::Vector{<:Recipe}, njobs::Int)
    nmix = div(length(recipes), njobs)
    rvecs = [vec(v) for v in collect(Iterators.partition(recipes, nmix))]
    if length(rvecs) > njobs
        excess = pop!(rvecs)
        for i in eachindex(excess)
            push!(rvecs[i], excess[i])
        end
    end
    rvecs
end

struct SerialPhenoJobConfig <: JobConfig end

function(cfg::SerialPhenoJobConfig)(
    allsp::Dict{Symbol, <:Species}, odict::Dict{Symbol, <:Order}, recipes::Vector{<:Recipe}
)
    phenodict = makephenodict(allsp)
    PhenoJob(odict, phenodict, recipes)
end

function makephenodict(allsp::Dict{Symbol, <:Species}
)
    Dict(spid => Dict(ikey.iid => sp.phenocfg(indiv)
        for (ikey, indiv) in merge(sp.pop, sp.children))
        for (spid, sp) in allsp)
end

Base.@kwdef struct ParallelPhenoJobConfig <: JobConfig
    njobs::Int
end

function(cfg::ParallelPhenoJobConfig)(
    allsp::Dict{Symbol, <:Species}, odict::Dict{Symbol, <:Order}, recipes::Vector{<:Recipe}
)
    phenodict = makephenodict(allsp)
    rsets = divvy(recipes, cfg.njobs)
    [PhenoJob(odict, phenodict, [r for r in recipes]) for recipes in rsets]
end

function(cfg::JobConfig)(allsp::Dict{Symbol, <:Species}, order::Order, recipes::Vector{<:Recipe})
    cfg(allsp, Dict(order.oid => order), recipes)
end