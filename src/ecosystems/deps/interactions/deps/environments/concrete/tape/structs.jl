module Structs

export TapeEnvironment, TapeEnvironmentCreator

using .....Interactions.Domains.Abstract: Domain
using ....Environments.Abstract: Environment, EnvironmentCreator
using ......Species.Phenotypes.Abstract: Phenotype

import ....Environments.Interfaces: create_environment, is_active

Base.@kwdef struct TapeEnvironmentCreator{D <: Domain} <: EnvironmentCreator{D}
    domain::D
    max_length::Int
end

Base.@kwdef mutable struct TapeEnvironment{D, P <: Phenotype} <: Environment{D}
    domain::D
    phenotypes::Vector{P}
    max_length::Int
    pos1::Float64 = 0.0
    pos2::Float64 = 0.0
    tape1::Vector{Float64} = [0.0]
    tape2::Vector{Float64} = [0.0]
end

function create_environment(
    environment_creator::TapeEnvironmentCreator{D},
    phenotypes::Vector{Phenotype}
) where {D <: Domain}
    return TapeEnvironment(
        domain = environment_creator.domain,
        phenotypes = phenotypes,
        max_length = environment_creator.max_length,
    )
end

function is_active(environment::TapeEnvironment)
    return length(environment.tape1) - 1 < environment.max_length
end

end