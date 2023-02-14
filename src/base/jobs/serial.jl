export PhenoJob, SerialPhenoJobConfig, ParallelPhenoJobConfig
export perform

struct PhenoJob{R <: Recipe, P <: Phenotype, O <: Order} <: Job
    odict::Dict{Symbol, O}
    recipes::Vector{R}
    phenodict::Dict{IndivKey, P}
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
    rvecs = collect(Iterators.partition(recipes, nmix))
    if length(rvecs) > n_subsets
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
    Job(odict, phenodict, recipes)
end

function makephenodict(allsp::Dict{Symbol, <:Species}
)
    phenodict = Dict{Symbol, Dict{IndivKey, Phenotype}}()
    for sp in allsp
        phenodict[sp.spid] = Dict(ikey => sp.phenocfg(indiv)
            for (ikey, indiv) in merge(sp.pop, sp.children)
        )
    end
    phenodict
end

Base.@kwdef struct ParallelPhenoJobConfig <: JobConfig
    njobs::Int
end

function(cfg::ParallelPhenoJobConfig)(
    allsp::Dict{Symbol, <:Species}, odict::Dict{Symbol, <:Order}, recipes::Vector{<:Recipe}
)
    phenodict = makephenodict(allsp)
    rsets = divvy(recipes, cfg.njobs)
    [PhenoJob(odict, phenodict, recipes) for recipes in rsets]
end

function(cfg::JobConfig)(allsp::Set{<:Species}, order::Order, recipes::Vector{<:Recipe})
    cfg(allsp, Set([order]), recipes)
end