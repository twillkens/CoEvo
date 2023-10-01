module Tape

export TapeEnvironment, TapeEnvironmentCreator

using ....Interactions.Domains.Abstract: Domain
using ...Environments.Abstract: Environment, EnvironmentCreator
using .....Species.Phenotypes.Abstract: Phenotype

struct TapeEnvironment{D <: Domain, P <: Phenotype} <: Environment 
    domain::D
    phenotypes::Vector{Phenotype}
    tape1::Vector{Float64}
    tape2::Vector{Float64}
    actions1::Vector{Float64}
    actions2::Vector{Float64}
    max_length::Int
end

struct TapeEnvironmentCreator{D <: Domain} <: EnvironmentCreator
    max_length::Int
end

end