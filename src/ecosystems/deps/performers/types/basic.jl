module Basic

export BasicPerformer

using Distributed: remotecall, fetch
using ....Ecosystems.Interactions.Results: Result
using ..Performers.Abstract: Performer

using ....Ecosystems.Jobs.Abstract: Job
using ....Ecosystems.Jobs.Basic: BasicJob
using ....Ecosystems.Interactions.Abstract: Interaction
using ....Ecosystems.Species.Phenotypes.Abstract: Phenotype
using ....Ecosystems.Interactions.Observers.Abstract: Observer
using ....Ecosystems.Interactions.Environments.Interfaces: create_environment, create_observer
using ....Ecosystems.Interactions.Methods.Interact: interact

import ..Performers.Interfaces: perform

Base.@kwdef struct BasicPerformer <: Performer 
    n_workers::Int
end

"""
    perform(job::BasicJob) -> Vector{InteractionResult}

Execute the given `job`, which contains various interaction recipes. Each recipe denotes 
specific entities to interact in a domain. The function processes these interactions and 
returns a list of their results.

# Arguments
- `job::BasicJob`: The job containing details about the interactions to be performed.

# Returns
- A `Vector` of `InteractionResult` instances, each detailing the outcome of an interaction.
"""
function perform(::BasicPerformer, job::BasicJob)
    results = Result[]
    for match in job.matches
        environment_creator = job.interactions[match.interaction_id].environment_creator
        observer_creators = job.interactions[match.interaction_id].observers
        phenotypes = [job.phenotypes[indiv_id] for indiv_id in match.indiv_ids]
        environment = create_environment(environment_creator, phenotypes)
        observers = [create_observer(creator, environment) for creator in observer_creators]
        result = interact(
            match.interaction_id, 
            match.indiv_ids,
            environment, 
            observers
        )
        push!(results, result)
    end
    return results
end


function perform(performer::BasicPerformer, jobs::Vector{<:Job})
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