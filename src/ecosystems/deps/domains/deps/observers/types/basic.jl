module Basic

using ..Abstract: Observation, Observer, ObservationMetric

mutable struct BasicObserver{O <: ObservationMetric, S <: Any} <: Observer
    metric::O
    state::S
end

struct BasicObservation{O <: ObservationMetric, D} <: Observation
    metric::O
    domain_id::String
    indiv_ids::Vector{Int}
    data::D
end

end