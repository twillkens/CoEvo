export observe!, create_observation, get_observations

using ..Abstract

function observe!(observer::Observer, args...)::Nothing
    throw(ErrorException("observe! not implemented for $(typeof(observer)) and $(typeof(args))"))
end

function create_observation(observer::Observer)::Observation
    throw(ErrorException("`create_observation`` not implemented for $(typeof(observer))"))
end

function get_observations(observations::Vector{<:Observation}, id::Int)
    observations = filter(observation -> observation.id == id, observations)
    return observations
end