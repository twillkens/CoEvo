using .Abstract: Observation, Observer, Metric


mutable struct BasicObserver{M <: Metric, S <: Any} <: Observer
    metric::M
    state::S
end

struct BasicObservation{M <: Metric, D} <: Observation
    metric::M
    domain_id::String
    indiv_ids::Vector{Int}
    data::D
end