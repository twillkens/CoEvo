export Job
export SerialJobConfig, ParallelJobConfig
export perform

struct Job{R <: Recipe, I <: Ingredient, G <: Genotype}
    recipes::Set{R}
    genodict::Dict{I, G}
end

function perform(job::Job)
    phenodict = makephenodict(job.genodict)
    mixes = getmixes(job.recipes, phenodict)
    Set(stir(mix) for mix in mixes)
end

function perform(jobs::Set{<:Job})
    futures = [remotecall(perform, i, job) for (i, job) in enumerate(jobs)]
    outcomes = [fetch(f) for f in futures]
    union(outcomes...)
end

struct SerialJobConfig <: JobConfig end

function(cfg::SerialJobConfig)(allsp::Set{<:Species}, recipes::Set{<:Recipe})
    allgenos = makeallgenos(allsp)
    genodict = makegenodict(allgenos, recipes)
    Job(recipes, genodict)
end

Base.@kwdef struct ParallelJobConfig <: JobConfig
    n_jobs::Int
end

function divvy(recipes::Set{<:Recipe}, n_subsets::Int)
    n_mix = div(length(recipes), n_subsets)
    recipe_vecs = collect(Iterators.partition(collect(recipes), n_mix))
    # If there are leftovers, divide the excess among the other subsets
    if length(recipe_vecs) > n_subsets
        excess = pop!(recipe_vecs)
        for i in eachindex(excess)
            push!(recipe_vecs[i], excess[i])
        end
    end
    Set(Set(rvec) for rvec in recipe_vecs)
end

function(cfg::ParallelJobConfig)(allsp::Set{<:Species}, recipes::Set{<:Recipe})
    allgenos = makeallgenos(allsp)
    rsets = divvy(recipes, cfg.n_jobs)
    Set(Job(recipes, makegenodict(allgenos, recipes)) for recipes in rsets)
end