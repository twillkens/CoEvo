module ContinuousPredictionGame

export scaled_arctangent, get_action!, apply_movement
export get_clockwise_distance, get_counterclockwise_distance

using .....Environments.Concrete.Tape: TapeEnvironment
using ......Domains.Concrete: ContinuousPredictionGameDomain
using ......Domains.Interfaces: measure
using .......Species.Phenotypes.Abstract: Phenotype
using .......Species.Phenotypes.Interfaces: act!
using .......Species.Phenotypes.GeneticPrograms: GeneticProgramPhenotype
using .......Species.Phenotypes.GnarlNetworks: GnarlNetworkPhenotype

import .....Environments.Interfaces: get_outcome_set, next!, is_active

function scaled_arctangent(x::Real, scale_value::Real)
    return Float32(scale_value * atan(x) / (π / 2))
end

function get_action!(
    entity::Phenotype, 
    clockwise_distance::Float32, 
    counterclockwise_distance::Float32, 
    communication::Vector{Float32}, 
    movement_scale::Float32
)
    input = [clockwise_distance ; counterclockwise_distance ; communication]
    action = act!(entity, input)
    movement_output = scaled_arctangent(action[1], movement_scale)
    communication_output = length(action) < 2 ? Float32[] : action[2:end]
    return movement_output, communication_output
end

function apply_movement(position::Float32, movement::Float32)
    return Float32(mod(position + movement, 2π))
end

function apply_movement(position::Real, movement::Real)
    apply_movement(Float32(position), Float32(movement))
end

get_clockwise_distance(position_1::Float32, position_2::Float32) = abs(position_1 - position_2)

get_counterclockwise_distance(position_1::Float32, position_2::Float32) = 
    Float32(2π - get_clockwise_distance(position_1, position_2))

get_counterclockwise_distance(clockwise_distance::Float32) = Float32(2π - clockwise_distance)

function next!(
    environment::TapeEnvironment{D, <:Phenotype, <:Phenotype}
) where {D <: ContinuousPredictionGameDomain}
    clockwise_distance = get_clockwise_distance(environment.position_1, environment.position_2)
    counterclockwise_distance = get_counterclockwise_distance(clockwise_distance)
    movement_1, environment.communication_1 = get_action!(
        environment.entity_1, 
        clockwise_distance, 
        counterclockwise_distance,
        environment.communication_2, 
        environment.movement_scale
    )
    movement_2, environment.communication_2 = get_action!(
        environment.entity_2, 
        counterclockwise_distance,
        clockwise_distance, 
        environment.communication_1, 
        environment.movement_scale
    )
    environment.position_1 = apply_movement(environment.position_1, movement_1)
    environment.position_2 = apply_movement(environment.position_2, -movement_2)

    closest_distance = min(clockwise_distance, counterclockwise_distance)
    push!(environment.distances, closest_distance)
end

function get_outcome_set(
    environment::TapeEnvironment{D, <:Phenotype, <:Phenotype}
) where {D <: ContinuousPredictionGameDomain}
    # As pi is the maximum distance between two entities, and the episode begins with them
    # maximally distant, the maximum distance score is pi * episode_length in the case
    # where the entities never move.
    maximum_distance_score = π * environment.episode_length
    distance_score = sum(environment.distances) / maximum_distance_score
    outcome_set = measure(environment.domain, distance_score)
    return outcome_set
end

end