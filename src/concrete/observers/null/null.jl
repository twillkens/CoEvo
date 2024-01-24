module Null

export NullObservation, NullObserver

import ....Interfaces: create_observation, observe!
using ....Abstract

struct NullObservation <: Observation end

struct NullObserver <: Observer end

function create_observation(::NullObserver)
    return NullObservation()
end

function observe!(::NullObserver, ::Environment)
    return nothing
end

end