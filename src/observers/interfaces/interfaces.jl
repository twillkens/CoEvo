export create_observation

function create_observation(observer::Observer)::Observation
    throw(ErrorException("`create_observation`` not implemented for $(typeof(observer))"))
end
