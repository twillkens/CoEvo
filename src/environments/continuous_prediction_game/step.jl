export scaled_arctangent, get_action!, apply_movement
export get_clockwise_distance, get_counterclockwise_distance

function is_active(environment::ContinuousPredictionGameEnvironment)
    return environment.timestep < environment.episode_length
end

function scaled_arctangent(x::Real, scale_value::Real)
    return Float32(scale_value * atan(x))
end

function get_action!(
    entity::Phenotype, 
    clockwise_distance::Float32, 
    counterclockwise_distance::Float32, 
    current_communication_of_other_entity::Vector{Float32}, 
    next_communication_of_this_entity::Vector{Float32},
    input_vector::Vector{Float32}
)
    input_vector[1] = clockwise_distance
    input_vector[2] = counterclockwise_distance
    if length(input_vector) > 2
        input_vector[3:end] .= current_communication_of_other_entity
    end

    if any(isnan, input_vector)
        println("NaN input vector: ", input_vector)
        println("clockwise_distance: ", clockwise_distance)
        println("counterclockwise_distance: ", counterclockwise_distance)
        println("communication: ", current_communication_of_other_entity)
        throw(ErrorException("NaN input vector"))
    end

    action = act!(entity, input_vector)
    if any(isnan, action)
        println("NaN action: ", action)
        println("input_vector: ", input_vector)
        println("entity: ", entity)
        throw(ErrorException("NaN action"))
    end
    movement_output = -atan(action[1])
    if isnan(movement_output)
        println("NaN movement_output: ", movement_output)
        println("action: ", action)
        println("entity: ", entity)
        throw(ErrorException("NaN movement_output"))
    end
    if length(action) > 1
        next_communication_of_this_entity .= atan.(action[2:end])
    end
    return movement_output #, communication_output
end

function apply_movement(position::Float32, movement::Float32)
    return Float32(mod(position + movement, 2π))
end

function apply_movement(position::Real, movement::Real)
    apply_movement(Float32(position), Float32(movement))
end

function get_clockwise_distance(position_1::Real, position_2::Real)
    direct_distance = position_2 - position_1
    absolute_distance = abs(direct_distance)
    if absolute_distance < 1e-6
        return 0.0f0
    end
    complementary_distance = Float32(2π - absolute_distance)
    if complementary_distance < 1e-6
        return 0.0f0
    end
    if direct_distance > 0
        clockwise_distance = complementary_distance
    else
        clockwise_distance = absolute_distance
    end
    return clockwise_distance
end

function get_counterclockwise_distance(clockwise_distance::Real)
    if clockwise_distance < 1e-6
        return 0.0f0
    end
    counterclockwise_distance = Float32(2π - clockwise_distance)
    return counterclockwise_distance
end

function get_counterclockwise_distance(position_1::Float32, position_2::Float32)
    clockwise_distance = get_clockwise_distance(position_1, position_2)
    conterclockwise_distance = get_counterclockwise_distance(clockwise_distance)
    return conterclockwise_distance
end

function step!(
    environment::ContinuousPredictionGameEnvironment{D, <:Phenotype, <:Phenotype}
) where {D <: PredictionGameDomain}
    environment.timestep += 1
    movement_1 = get_action!(
        environment.entity_1, 
        environment.clockwise_distance, 
        environment.counterclockwise_distance,
        environment.current_communication_2, 
        environment.next_communication_1,
        environment.input_vector
    )
    movement_2 = get_action!(
        environment.entity_2, 
        environment.counterclockwise_distance,
        environment.clockwise_distance, 
        environment.current_communication_1, 
        environment.next_communication_2,
        environment.input_vector
    )
    @inbounds for (index, value) in enumerate(environment.next_communication_1)
        environment.current_communication_1[index] = value
    end

    @inbounds for (index, value) in enumerate(environment.next_communication_2)
        environment.current_communication_2[index] = value
    end
    environment.position_1 = apply_movement(environment.position_1, movement_1)
    environment.position_2 = apply_movement(environment.position_2, movement_2)
    environment.clockwise_distance = get_clockwise_distance(
        environment.position_1, environment.position_2
    )
    environment.counterclockwise_distance = get_counterclockwise_distance(
        environment.clockwise_distance
    )
    environment.distances[environment.timestep] = min(
        environment.clockwise_distance, environment.counterclockwise_distance
    )
end
