module Cache

export CachePerformer

import ..Performers: perform

using ...Phenotypes: Phenotype
using ...Results: Result
using ...Interactions: Interaction, interact
using ...Observers: Observer
using ...Environments: create_environment
using ...Jobs: Job
using ...Jobs.Basic: BasicJob
using ...Matches.Basic: BasicMatch
using ..Performers: Performer
using ..Performers.Basic: BasicPerformer

Base.@kwdef struct CachePerformer <: Performer 
    n_workers::Int = 1
    cache::Dict{BasicMatch, Result} = Dict{BasicMatch, Result}()
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
    filtered_job = BasicJob(job.interactions, job.phenotypes, uncached_matches)
    return filtered_job, cached_results
end

function perform(performer::CachePerformer, jobs::Vector{J}) where {J <: Job}
    filtered_jobs_cached_results = [filter_cached_matches(performer, job) for job in jobs]
    filtered_jobs = [item[1] for item in filtered_jobs_cached_results]
    cached_results = vcat([item[2] for item in filtered_jobs_cached_results]...)
    basic_performer = BasicPerformer(performer.n_workers)
    new_results = perform(basic_performer, filtered_jobs)
    empty!(performer.cache)
    [
        push!(
            performer.cache, 
            BasicMatch(result.interaction_id, result.individual_ids) => result
        )
        for result in new_results
    ]
    all_results = [cached_results ; new_results]
    return all_results
end

end