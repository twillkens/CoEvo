module Null

export NullObservation

using ...Observers.Abstract: Observation, Observer, ObserverCreator
using .....Metrics.Observations.Abstract: ObservationMetric
using .....Metrics.Observations.Types: NullObservationMetric


Base.@kwdef struct NullObservation{O, D} <: Observation{O, D}
    metric::O = NullObservationMetric()
    interaction_id::String = ""
    indiv_ids::Vector{Int} = Int[]
    data::D = nothing
end


end