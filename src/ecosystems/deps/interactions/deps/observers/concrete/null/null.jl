module Null

export NullObservation

using ...Observers.Abstract: Observation, Observer
using .....Metrics.Abstract: Metric
using .....Metrics.Concrete.Common: NullMetric


Base.@kwdef struct NullObservation{O, D} <: Observation{O, D}
    metric::O = NullMetric()
    interaction_id::String = ""
    indiv_ids::Vector{Int} = Int[]
    data::D = nothing
end


end