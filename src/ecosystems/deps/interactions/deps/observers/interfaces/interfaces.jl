module Interfaces

export create_observation

using ...Observers.Abstract: Observer, Observation

function create_observation(observer::Observer)::Observation
    error("`create_observation`` not implemented for $(typeof(observer))")
end

end