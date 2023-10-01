module Basic

using Distributed: remotecall, fetch
using ....Ecosystems.Results: Result
using ..Performers.Abstract: Performer
using ...Interactions.Observers.Interfaces: observe!, create_observation

using ....Ecosystems.Jobs.Abstract: Job
using ....Ecosystems.Interactions.Abstract: Interaction
using ....Ecosystems.Species.Phenotypes.Abstract: Phenotype
using ....Ecosystems.Interactions.Observers.Abstract: Observer
import ..Interfaces: perform

struct BasicPerformer <: Performer 
    n_workers::Int
end

function interact(
    domain::Domain, 
    observers::Vector{<:Observer},
    phenotypes::Vector{<:Phenotype}
)
    refresh!(domain, observers, phenotypes)
    observe!(domain, observers)
    while is_active(domain)
        next!(domain)
        observe!(domain, observers)
    end
    indiv_ids = [pheno.id for pheno in phenotypes]
    outcome_set = get_outcome_set(domain)
    observations = [create_observation(observer) for observer in observers]
    result = BasicResult(domain.id, indiv_ids, outcome_set, observations)
    return result
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
function perform(::BasicPerformer, job::Job)
    all_environments = Dict(
        domain.id => create_environment(domain.environment_creator, domain.id) 
        for domain in job.domains
    )
    all_observers = Dict(
        domain.id => domain.observers
        for domain in job.domains
    )
    results = Result[]
    for match in job.matches
        environment = all_environments[match.domain_id]
        observers = all_observers[match.domain_id]
        phenotypes = [job.pheno_dict[indiv_id] for indiv_id in match.indiv_ids]
        result = interact(environment, observers, phenotypes)
        push!(results, result)
    end
    return results
end


function perform(performer::BasicPerformer, jobs::Vector{Job})
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