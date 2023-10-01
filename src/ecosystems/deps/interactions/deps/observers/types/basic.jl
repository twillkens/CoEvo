module Basic

export BasicObserver, BasicObservation

using ..Observers.Abstract: Observation, Observer, ObserverCreator
using ....Metrics.Observation.Abstract: ObservationMetric

struct BasicObserverCreator{O <: ObservationMetric} <: ObserverCreator
    metric::O
end

mutable struct BasicObserver{O <: ObservationMetric} <: Observer
    metric::O
end

struct BasicObservation{O <: ObservationMetric, D <: Any} <: Observation
    metric::O
    interaction_id::String
    indiv_ids::Vector{Int}
    data::D
end

end