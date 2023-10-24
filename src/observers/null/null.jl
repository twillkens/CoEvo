module Null

export NullObservation

using ...Observers: Observation, Observer
using ...Metrics.Common: NullMetric

Base.@kwdef struct NullObservation{O, D} <: Observation{O, D}
    metric::O = NullMetric()
    interaction_id::String = ""
    individual_ids::Vector{Int} = Int[]
    data::D = nothing
end

end