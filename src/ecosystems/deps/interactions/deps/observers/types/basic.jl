module Basic

export BasicObserver, BasicObservation

using ..Observers.Abstract: Observation, Observer
using ....Metrics.Observation.Abstract: ObservationMetric

mutable struct BasicObserver{O <: ObservationMetric} <: Observer
    metric::O
end

struct BasicObservation{O <: ObservationMetric, D} <: Observation
    metric::O
    interaction_id::String
    indiv_ids::Vector{Int}
    data::D
end

end