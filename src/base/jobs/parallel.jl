export ParallelJob, ParallelJobsConfig

Base.@kwdef struct ParallelJobsConfig <: JobConfig
    n_jobs::Int
    # lru::LRUCache = LRU{}
end

struct ParallelJob <: Job
    recipes::Set{Recipe}
    genodict::Dict{String, Genotype}
    function ParallelJob(recipes::Set{Recipe}, genodict::Dict{String, Genotype})
        pairs = [key => genodict[key] 
        for recipe in recipes
            for key in Set{String}(recipe)]
        pairs = Dict(pairs)
        new(recipes, job_genodict)
    end
end


function Set{Set{Recipe}}(recipes::Set{<:Recipe}, n_subsets::Int)
    n_mix = div(length(recipes), n_subsets)
    recipe_vecs = collect(Iterators.partition(collect(recipes), n_mix))
    # If there are leftovers, divide the excess among the other subsets
    if length(recipe_vecs) > n_subsets
        excess = pop!(recipe_vecs)
        for i in eachindex(excess)
            push!(recipe_vecs[i], excess[i])
        end
    end
    Set([Set{Recipe}(rvec) for rvec in recipe_vecs])
end

function Set{Set{Recipe}}(order::Order, allsp::Set{<:Species}, n_jobs::Int)
    recipes = order(allsp)
    Set{Set{Recipe}}(recipes, n_jobs)
end

function Set{Recipe}(orders::Set{<:Order}, allsp::Set{<:Species})
    union([order(allsp) for order in orders]...)
end

function Set{Set{Recipe}}(orders::Set{<:Order}, allsp::Set{<:Species}, n_jobs::Int)
    recipes = Set{Recipe}(orders, allsp)
    Set{Set{Recipe}}(recipes, n_jobs)
end

function(cfg::ParallelJobsConfig)(orders::Set{<:Order}, allsp::Set{<:Species})
    recipe_sets = Set{Set{Recipe}}(orders, allsp, cfg.n_jobs)
    genodict = Dict{String, Genotype}(pops)
    Set([ParallelJob(recipes, genodict) for recipes in recipe_sets])
end

function Set{Mix}(job::ParallelJob)
    Set{Mix}(job.recipes, job.genodict)
end

function Set{Outcome}(job::ParallelJob)
    mixes = Set{Mix}(job.recipes, job.genodict)
    Set([(mix)() for mix in mixes])
end

function Set{Outcome}(jobs::Set{ParallelJob})
    futures = [remotecall(Set{Outcome}, i, job) for (i, job) in enumerate(jobs)]
    outcomes = [fetch(f) for f in futures]
    union(outcomes...)
end
