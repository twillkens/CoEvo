module Basic

export BasicPerformer

import ..Performers: perform

using Distributed: remotecall, fetch
using ...Phenotypes: Phenotype
using ...Results: Result
using ...Interactions: Interaction, interact
using ...Observers: Observer
using ...Environments: create_environment
using ...Jobs.Basic: BasicJob
using ..Performers: Performer

Base.@kwdef struct BasicPerformer <: Performer 
    n_workers::Int
end

function perform(::BasicPerformer, job::BasicJob)
    results = Result[]
    for match in job.matches
        interaction = job.interactions[match.interaction_id]
        phenotypes = Phenotype[
            job.phenotypes[individual_id] for individual_id in match.individual_ids
        ]
        result = interact(
            interaction,
            match.individual_ids,
            phenotypes
        )
        push!(results, result)
    end
    return results
end

function perform(performer::BasicPerformer, jobs::Vector{<:BasicJob})
    if length(jobs) == 1
        results = perform(performer, jobs[1])
    else
        futures = [remotecall(perform, i, performer, job) for (i, job) in enumerate(jobs)]
        results = [fetch(f) for f in futures]
    end
    results = vcat(results...)
    return results
end

end