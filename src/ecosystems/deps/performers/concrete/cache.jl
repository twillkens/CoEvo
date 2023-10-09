module Cache

export CachePerformer

using Distributed: remotecall, fetch

using ....Species.Phenotypes.Abstract: Phenotype
using ....Interactions.Results: Result
using ....Interactions.Abstract: Interaction
using ....Interactions.Observers.Abstract: Observer
using ....Interactions.Environments.Interfaces: create_environment
using ....Interactions.Interfaces: interact
using ....Jobs.Basic: BasicJob
using ....Performers.Abstract: Performer
using ....Interactions.MatchMakers.Matches.Abstract: Match

import ...Performers.Interfaces: perform

Base.@kwdef struct CachePerformer <: Performer 
    n_workers::Int = 1
    cache::Dict{Match, Result} = Dict{Match, Result}()
end

function filter_cached_matches(performer::CachePerformer, job::BasicJob)
    cached_results = Result[]
    uncached_matches = BasicMatch[]
    
    for match in job.matches
        if haskey(performer.cache, match)
            # Retrieve the cached result
            push!(cached_results, performer.cache[match])
        else
            push!(uncached_matches, match)
        end
    end
    
    # Return the modified job without the matches that are already cached
    # and the cached results
    return BasicJob(job.interactions, job.phenotypes, uncached_matches), cached_results
end


function perform(performer::CachePerformer, job::BasicJob)
    results = Result[]
    cache_pairs = Pair{Match, Result}[]
    for match in job.matches
        if haskey(performer.cache, match)
            # Use cached result
            push!(results, performer.cache[match])
        else
            interaction = job.interactions[match.interaction_id]
            phenotypes = Phenotype[job.phenotypes[indiv_id] for indiv_id in match.indiv_ids]
            result = interact(
                interaction,
                match.indiv_ids,
                phenotypes
            )
            # Cache the result
            push!(results, result)
            push!(cache_pairs, match => result)
        end
    end

    empty!(performer.cache)
    for (match, result) in cache_pairs
        performer.cache[match] = result
    end
    println("Cache size: ", length(performer.cache))
    return results
end

function perform_parallel(performer::CachePerformer, job::BasicJob, worker_id::Int)
    # Temporarily detach the cache
    cache = performer.cache
    performer.cache = Dict{Match, Any}()
    
    # Use remotecall without sending the cache
    future = remotecall(perform, worker_id, performer, job)

    # Re-attach the cache
    performer.cache = cache

    return future
end

function perform(performer::CachePerformer, jobs::Vector{<:BasicJob})
    if length(jobs) == 1
        return perform(performer, jobs[1])
    end
    
    all_results = []
    workers_list = workers()
    for (idx, job) in enumerate(jobs)
        # Assuming we have as many jobs as workers, dispatch job[idx] to worker[idx]
        worker_id = workers_list[idx]
        
        # Filter out matches that are already cached
        new_job, cached_results = filter_cached_matches(performer, job)
        append!(all_results, cached_results)
        
        # Dispatch only jobs with uncached matches
        if !isempty(new_job.matches)
            results = perform_parallel(performer, new_job, worker_id)
            append!(all_results, results)
        end
    end
    
    return all_results
end


end