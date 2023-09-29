module Interfaces

export observe!, create_observation

using ..Abstract: Domain, Observer, Observation

function observe!(domain::Domain, observer::Observer)
    error("`observe!`` not implemented for $(typeof(domain)), $(typeof(observer))")
end

function create_observation(observer::Observer)::Observation
    error("`create_observation`` not implemented for $(typeof(observer))")
end

end