module Stateless

export StatelessEnvironment, StatelessEnvironmentCreator

using ....Interactions.Domains.Abstract: Domain
using ...Environments.Abstract: Environment, EnvironmentCreator
using .....Species.Phenotypes.Abstract: Phenotype

import ...Environments.Interfaces: next!, is_active, create_environment


struct StatelessEnvironment{D <: Domain, P <: Phenotype} <: Environment{D, P}
    domain::D
    phenotypes::Vector{P}
end

struct StatelessEnvironmentCreator{D <: Domain} <: EnvironmentCreator{D}
    domain::D
end

function create_environment(
    env_creator::StatelessEnvironmentCreator,
    phenotypes::Vector{<:Phenotype}
)
    return StatelessEnvironment(
        env_creator.domain,
        phenotypes
    )
end

function is_active(::StatelessEnvironment)
    return false
end

end