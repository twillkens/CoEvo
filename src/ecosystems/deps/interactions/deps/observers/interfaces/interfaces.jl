module Interfaces

export observe!, create_observation

using ..Abstract: Environment, Observer, Observation

function observe!(environment::Environment, observer::Observer)
    error("`observe!`` not implemented for $(typeof(interaction)), $(typeof(observer))")
end

function create_observation(observer::Observer)::Observation
    error("`create_observation`` not implemented for $(typeof(observer))")
end

end