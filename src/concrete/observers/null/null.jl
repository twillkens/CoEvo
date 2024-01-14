module Null

export NullObservation, NullObserver

import ....Interfaces: create_observation
using ....Abstract

struct NullObservation <: Observation end

struct NullObserver <: Observer end

function create_observation(::NullObserver)
    return NullObservation()
end

end