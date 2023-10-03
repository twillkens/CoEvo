module Basic

export BasicObserver, BasicObservation

using ...Observers.Abstract: Observation, Observer, ObserverCreator
using .....Metrics.Observations.Abstract: ObservationMetric

struct BasicObserverCreator{O <: ObservationMetric} <: ObserverCreator{O}
    metric::O
end

mutable struct BasicObserver{O <: ObservationMetric} <: Observer{O}
    metric::O
end

struct BasicObservation{O <: ObservationMetric, D <: Any} <: Observation{O, D}
    metric::O
    interaction_id::String
    indiv_ids::Vector{Int}
    data::D
end

end