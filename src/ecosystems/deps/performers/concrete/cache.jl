module Cache

export CachePerformer

using Distributed: remotecall, fetch, workers

using ....Species.Phenotypes.Abstract: Phenotype
using ....Interactions.Results: Result
using ....Interactions.Abstract: Interaction
using ....Interactions.Observers.Abstract: Observer
using ....Interactions.Environments.Interfaces: create_environment
using ....Interactions.Interfaces: interact
using ....Jobs.Basic: BasicJob
using ....Jobs.Abstract: Job
using ....Performers.Abstract: Performer
using ....Performers.Concrete.Basic: BasicPerformer
using ....Interactions.MatchMakers.Matches.Abstract: Match
using ....Interactions.MatchMakers.Matches.Basic: BasicMatch

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


function perform(performer::CachePerformer, jobs::Vector{J}) where {J <: Job}
    filtered_jobs_cached_results = [filter_cached_matches(performer, job) for job in jobs]
    filtered_jobs = [item[1] for item in filtered_jobs_cached_results]
    cached_results = vcat([item[2] for item in filtered_jobs_cached_results]...)
    println("Cached results: ", length(cached_results))
    basic_performer = BasicPerformer(performer.n_workers)
    new_results = perform(basic_performer, filtered_jobs)
    empty!(performer.cache)
    [
        push!(performer.cache, BasicMatch(result.interaction_id, result.indiv_ids) => result)
        for result in new_results
    ]
    all_results = [cached_results ; new_results]
    return all_results
end


end