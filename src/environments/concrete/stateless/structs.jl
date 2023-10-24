module Structs

export StatelessEnvironment, StatelessEnvironmentCreator

using .....Domains.Abstract: Domain
using ....Environments.Abstract: Environment, EnvironmentCreator
using ......Species.Phenotypes.Abstract: Phenotype

import ....Environments.Interfaces: is_active, create_environment


struct StatelessEnvironment{D, P <: Phenotype} <: Environment{D}
    domain::D
    phenotypes::Vector{P}
end

Base.@kwdef struct StatelessEnvironmentCreator{D} <: EnvironmentCreator{D}
    domain::D
end

function create_environment(
    environment_creator::StatelessEnvironmentCreator{D},
    phenotypes::Vector{Phenotype}
) where {D <: Domain}
    return StatelessEnvironment(
        environment_creator.domain,
        phenotypes
    )
end

function is_active(::StatelessEnvironment)
    return false
end

end