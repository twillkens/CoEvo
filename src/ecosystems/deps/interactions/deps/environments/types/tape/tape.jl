module Tape

export TapeEnvironment, TapeEnvironmentCreator

using ....Interactions.Domains.Abstract: Domain
using ...Environments.Abstract: Environment, EnvironmentCreator
using .....Species.Phenotypes.Abstract: Phenotype

struct TapeEnvironment{D <: Domain, P <: Phenotype} <: Environment 
    domain::D
    phenotypes::Vector{Phenotype}
    max_length::Int
    tape1::Vector{Float64}
    tape2::Vector{Float64}
    actions1::Vector{Float64}
    actions2::Vector{Float64}
end

struct TapeEnvironmentCreator{D <: Domain} <: EnvironmentCreator
    domain::D
    max_length::Int
end

function create_environment(
    env_creator::TapeEnvironmentCreator,
    phenotypes::Vector{<:Phenotype}
)
    return TapeEnvironment(
        env_creator.domain,
        phenotypes,
        env_creator.max_length,
        Float64[],
        Float64[],
        Float64[],
        Float64[],
    )
end

end