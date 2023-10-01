module Stateless

export StatelessEnvironment, StatelessEnvironmentCreator

using ....Interactions.Domains.Abstract: Domain
using ...Environments.Abstract: Environment, EnvironmentCreator
using .....Species.Phenotypes.Abstract: Phenotype

import ...Environments.Interfaces: next!, is_active, create_environment


struct StatelessEnvironment{D <: Domain, P <: Phenotype} <: Environment
    interaction_id::String
    domain::D
    indiv_ids::Vector{Int}
    phenotypes::Vector{P}
end

struct StatelessEnvironmentCreator{D <: Domain} <: EnvironmentCreator
    domain::D
end

function create_environment(
    env_creator::StatelessEnvironmentCreator,
    domain::Domain,
    indiv_ids::Vector{Int},
    phenotypes::Vector{<:Phenotype}
)
    return StatelessEnvironment(
        env_creator.domain.id,
        domain,
        indiv_ids,
        phenotypes
    )
end

function is_active(::StatelessEnvironment)
    return false
end

end