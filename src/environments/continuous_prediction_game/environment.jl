export ContinuousPredictionGameEnvironment, ContinuousPredictionGameEnvironmentCreator

Base.@kwdef struct ContinuousPredictionGameEnvironmentCreator{
    D <: Domain
} <: EnvironmentCreator{D}
    domain::D
    episode_length::Int
    communication_dimension::Int = 0
end

Base.@kwdef mutable struct ContinuousPredictionGameEnvironment{
    D, P1 <: Phenotype, P2 <: Phenotype
} <: Environment{D}
    domain::D
    entity_1::P1
    entity_2::P2
    episode_length::Int
    timestep::Int = 0
    position_1::Float32 = Float32(π)
    position_2::Float32 = 0.0f0
    movement_scale::Float32 = 1.0f0
    distances::Vector{Float32} = Float32[]
    current_communication_1::Vector{Float32}
    current_communication_2::Vector{Float32}
    next_communication_1::Vector{Float32}
    next_communication_2::Vector{Float32}
    input_vector::Vector{Float32}
    clockwise_distance::Float32 = Float32(π)
    counterclockwise_distance::Float32 = Float32(π)
end

function create_environment(
    environment_creator::ContinuousPredictionGameEnvironmentCreator{D},
    phenotypes::Vector{Phenotype},
) where {D <: Domain}
    reset!(phenotypes[1])
    reset!(phenotypes[2])
    environment = ContinuousPredictionGameEnvironment(
        domain = environment_creator.domain,
        entity_1 = phenotypes[1],
        entity_2 = phenotypes[2],
        episode_length = environment_creator.episode_length,
        timestep = 0,
        position_1 = Float32(π),
        position_2 = 0.0f0,
        movement_scale = 1.0f0,
        distances = zeros(Float32, environment_creator.episode_length),
        current_communication_1 = zeros(Float32, environment_creator.communication_dimension),
        current_communication_2 = zeros(Float32, environment_creator.communication_dimension),
        next_communication_1 = zeros(Float32, environment_creator.communication_dimension),
        next_communication_2 = zeros(Float32, environment_creator.communication_dimension),
        input_vector = zeros(Float32, 2 + environment_creator.communication_dimension),
        clockwise_distance = Float32(π),
        counterclockwise_distance = Float32(π)
    )
    return environment
end

function get_phenotypes(environment::ContinuousPredictionGameEnvironment)
    return [environment.entity_1, environment.entity_2]
end