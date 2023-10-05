module Basic

export BasicObserver, BasicObservation

using ...Observers.Abstract: Observation, Observer
using .....Metrics.Abstract: Metric


mutable struct BasicObserver{M <: Metric} <: Observer{M}
    metric::M
end

struct BasicObservation{M <: Metric, D <: Any} <: Observation{M, D}
    metric::M
    interaction_id::String
    indiv_ids::Vector{Int}
    data::D
end

end