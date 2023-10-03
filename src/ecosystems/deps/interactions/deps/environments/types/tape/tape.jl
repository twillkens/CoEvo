module Tape

export TapeEnvironment, TapeEnvironmentCreator

using ....Interactions.Domains.Abstract: Domain
using ...Environments.Abstract: Environment, EnvironmentCreator
using .....Species.Phenotypes.Abstract: Phenotype

struct TapeEnvironment{D <: Domain, P <: Phenotype} <: Environment{D, P}
    domain::D
    phenotypes::Vector{Phenotype}
    max_length::Int
    tape1::Vector{Float64}
    tape2::Vector{Float64}
    actions1::Vector{Float64}
    actions2::Vector{Float64}
end

struct TapeEnvironmentCreator{D <: Domain} <: EnvironmentCreator{D}
    domain::D
    max_length::Int
end

function create_environment(
    environment_creator::TapeEnvironmentCreator,
    phenotypes::Vector{<:Phenotype}
)
    return TapeEnvironment(
        environment_creator.domain,
        phenotypes,
        environment_creator.max_length,
        Float64[],
        Float64[],
        Float64[],
        Float64[],
    )
end

end