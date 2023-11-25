export observe!, create_observation

function observe!(observer::Observer, args...)::Nothing
    throw(ErrorException("observe! not implemented for $(typeof(observer)) and $(typeof(args))"))
end

function create_observation(observer::Observer)::Observation
    throw(ErrorException("`create_observation`` not implemented for $(typeof(observer))"))
end
