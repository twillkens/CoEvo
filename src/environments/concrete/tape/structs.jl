module Structs

export TapeEnvironment, TapeEnvironmentCreator

using .....Interactions.Domains.Abstract: Domain
using ....Environments.Abstract: Environment, EnvironmentCreator
using ......Species.Phenotypes.Abstract: Phenotype
using ......Species.Phenotypes.Interfaces: reset!

import ....Environments.Interfaces: create_environment, is_active

Base.@kwdef struct TapeEnvironmentCreator{D <: Domain} <: EnvironmentCreator{D}
    domain::D
    episode_length::Int
    communication_dimension::Int = 0
end

Base.@kwdef mutable struct TapeEnvironment{D, P1 <: Phenotype, P2 <: Phenotype} <: Environment{D}
    domain::D
    entity_1::P1
    entity_2::P2
    episode_length::Int
    timestep::Int = 0
    position_1::Float32 = Float32(π)
    position_2::Float32 = 0.0f0
    movement_scale::Float32 = 1.0f0
    distances::Vector{Float32} = Float32[]
    current_communication_1::Vector{Float32} = Float32[]
    current_communication_2::Vector{Float32} = Float32[]
    next_communication_1::Vector{Float32} = Float32[]
    next_communication_2::Vector{Float32} = Float32[]
    input_vector::Vector{Float32} = [0.0f0 for _ in 1:2 + length(current_communication_1)]
    clockwise_distance::Float32 = Float32(π)
    counterclockwise_distance::Float32 = Float32(π)
end

function create_environment(
    environment_creator::TapeEnvironmentCreator{D},
    phenotypes::Vector{Phenotype}
) where {D <: Domain}
    reset!(phenotypes[1])
    reset!(phenotypes[2])
    return TapeEnvironment(
        domain = environment_creator.domain,
        entity_1 = phenotypes[1],
        entity_2 = phenotypes[2],
        episode_length = environment_creator.episode_length,
        distances = zeros(Float32, environment_creator.episode_length),
        current_communication_1 = zeros(Float32, environment_creator.communication_dimension),
        current_communication_2 = zeros(Float32, environment_creator.communication_dimension),
        next_communication_1 = zeros(Float32, environment_creator.communication_dimension),
        next_communication_2 = zeros(Float32, environment_creator.communication_dimension),
    )
end

function is_active(environment::TapeEnvironment)
    return environment.timestep < environment.episode_length
end

end