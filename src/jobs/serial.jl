export PhenoJob, SerialPhenoJobConfig, ParallelPhenoJobConfig
export perform

# TODO: Check types of phenodict
struct PhenoJob{R <: Recipe, O <: Order} <: Job
    odict::Dict{Symbol, O}
    phenodict::Dict
    recipes::Vector{R}
end

function perform(job::Job)
    mixes = getmixes(job)
    [stir(mix) for mix in mixes]
end

# TODO: Check parallel processing
function perform(jobs::Vector{<:Job})
    futures = [remotecall(perform, i, job) for (i, job) in enumerate(jobs)]
    outcomes = [fetch(f) for f in futures]
    vcat(outcomes...)
end

function divvy(recipes::Vector{<:Recipe}, njobs::Int)
    n = length(recipes)
    # Base size for each job
    base_size = div(n, njobs)
    
    # Number of jobs that will take an extra item
    extras = n % njobs

    partitions = Vector{Vector{<:Recipe}}()
    start_idx = 1

    for i in 1:njobs
        end_idx = start_idx + base_size - 1
        if extras > 0
            end_idx += 1
            extras -= 1
        end

        push!(partitions, recipes[start_idx:end_idx])

        start_idx = end_idx + 1
    end
    partitions
end

struct SerialPhenoJobConfig <: JobConfig end

function makephenodict(allsp::Dict{Symbol, <:Species}
)
    Dict(spid => Dict(ikey.iid => sp.phenocfg(indiv.ikey, indiv.geno)
        for (ikey, indiv) in merge(sp.pop, sp.children))
        for (spid, sp) in allsp)
end

function(cfg::SerialPhenoJobConfig)(
    allsp::Dict{Symbol, <:Species}, odict::Dict{Symbol, <:Order}, recipes::Vector{<:Recipe}
)
    phenodict = makephenodict(allsp)
    PhenoJob(odict, phenodict, recipes)
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