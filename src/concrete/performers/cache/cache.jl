module Cache

export CachePerformer

import ....Interfaces: perform
using ....Abstract
using ....Interfaces
using ...Jobs.Simple: SimpleJob
using ...Matches.Basic: BasicMatch
using ..Performers.Basic: BasicPerformer

Base.@kwdef struct CachePerformer <: Performer 
    n_workers::Int = 1
    cache::Dict{BasicMatch, Result} = Dict{BasicMatch, Result}()
end

function filter_cached_matches(performer::CachePerformer, job::SimpleJob)
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
    filtered_job = SimpleJob(job.interactions, job.phenotypes, uncached_matches)
    return filtered_job, cached_results
end

function perform(performer::CachePerformer, jobs::Vector{J}) where {J <: Job}
    filtered_jobs_cached_results = [filter_cached_matches(performer, job) for job in jobs]
    filtered_jobs = [item[1] for item in filtered_jobs_cached_results]
    cached_results = vcat([item[2] for item in filtered_jobs_cached_results]...)
    basic_performer = BasicPerformer(performer.n_workers)
    new_results = perform(basic_performer, filtered_jobs)
    empty!(performer.cache)
    for result in new_results
        push!(
            performer.cache, 
            BasicMatch(result.interaction_id, result.individual_ids, result.species_ids) => result
        )
    end
    all_results = Result[cached_results ; new_results]
    return all_results
end

end