module Stateless

export StatelessEnvironment, StatelessEnvironmentCreator

using ....Interactions.Domains.Abstract: Domain
using ...Environments.Abstract: Environment, EnvironmentCreator
using .....Species.Phenotypes.Abstract: Phenotype

import ...Environments.Interfaces: next!, is_active, create_environment


struct StatelessEnvironment{D, P <: Phenotype} <: Environment{D}
    domain::D
    phenotypes::Vector{P}
end

struct StatelessEnvironmentCreator{D} <: EnvironmentCreator{D}
    domain::D
end

function create_environment(
    environment_creator::StatelessEnvironmentCreator{D},
    phenotypes::Vector{P}
) where {D <: Domain, P <: Phenotype}
    return StatelessEnvironment(
        environment_creator.domain,
        phenotypes
    )
end

function is_active(::StatelessEnvironment)
    return false
end

end