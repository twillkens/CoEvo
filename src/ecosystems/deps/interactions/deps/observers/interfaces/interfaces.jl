module Interfaces

export create_observation

using ...Observers.Abstract: Observer, Observation

function create_observation(observer::Observer)::Observation
    throw(ErrorException("`create_observation`` not implemented for $(typeof(observer))"))
end


end