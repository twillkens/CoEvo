module CollisionGame

export CollisionGameEnvironment, CollisionGameEnvironmentCreator

import ..Environments: get_outcome_set, create_environment, is_active, step!

using ...Domains: Domain, measure
using ...Domains.PredictionGame: PredictionGameDomain
using ...Phenotypes: Phenotype, act!, reset!
using ..Environments: Environment, EnvironmentCreator

Base.@kwdef struct CollisionGameEnvironmentCreator{D <: Domain} <: EnvironmentCreator{D}
    domain::D
    initial_distance::Float64 = 5.0
    episode_length::Int = 128
    communication_dimension::Int = 1
end

Base.@kwdef mutable struct CollisionGameEnvironment{
    D, P1 <: Phenotype, P2 <: Phenotype
} <: Environment{D}
    domain::D
    entity_1::P1
    entity_2::P2
    position_1::Float32
    position_2::Float32
    last_communication_1::Float32
    last_communication_2::Float32
    maximum_distance::Float32
    episode_length::Int
    timestep::Int
end

function create_environment(
    environment_creator::CollisionGameEnvironmentCreator{D},
    phenotypes::Vector{Phenotype}
) where {D <: Domain}
    entity_1, entity_2 = phenotypes
    reset!(entity_1)
    reset!(entity_2)
    initial_distance = environment_creator.initial_distance
    position_1 = Float32(-(initial_distance / 2)) 
    position_2 = -position_1
    last_communication_1 = Float32(0.0)
    last_communication_2 = Float32(0.0)
    maximum_distance = Float32(initial_distance + (2 * environment_creator.episode_length))
    timestep = 1
    environment= CollisionGameEnvironment(
        domain = environment_creator.domain,
        entity_1 = entity_1,
        entity_2 = entity_2,
        position_1 = position_1,
        position_2 = position_2,
        last_communication_1 = last_communication_1,
        last_communication_2 = last_communication_2,
        maximum_distance = maximum_distance,
        episode_length = environment_creator.episode_length,
        timestep = timestep,
    )
    return environment
end

entities_have_collided(environment::CollisionGameEnvironment) = (
     environment.position_1 > environment.position_2
)

episode_is_over(environment::CollisionGameEnvironment) = (
    environment.timestep > environment.episode_length
)

function is_active(environment::CollisionGameEnvironment)
    if episode_is_over(environment) || entities_have_collided(environment)
        return false
    else
        return true
    end
end

function get_distance_between_entities(environment::CollisionGameEnvironment)
   return abs(environment.position_1 - environment.position_2) / environment.maximum_distance
end

function step!(
    environment::CollisionGameEnvironment# {D, <:Phenotype}
) #where {D <: CollisionGameDomain}
    distance = get_distance_between_entities(environment)
    input_to_entity_1 = [distance, environment.last_communication_2]
    input_to_entity_2 = [distance, environment.last_communication_1]

    action_1, communication_1 = act!(environment.entity_1, input_to_entity_1)
    action_2, communication_2 = act!(environment.entity_2, input_to_entity_2)

    environment.position_1 += action_1
    environment.position_2 -= action_2

    environment.last_communication_1 = communication_1
    environment.last_communication_2 = communication_2

    environment.timestep += 1
end


function get_outcome_set(
    environment::CollisionGameEnvironment # {D, <:Phenotype}
) # where {D <: CollisionGameDomain}
    collision_occured = entities_have_collided(environment)
    distance_score = collision_occured ? 0.0 : 1.0
    outcome_set = measure(environment.domain, distance_score)
    return outcome_set
end

end
