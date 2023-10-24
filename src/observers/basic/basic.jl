module Basic

export BasicObserver, BasicObservation

using ...Metrics.Abstract: Metric
using ..Observers.Abstract: Observation, Observer

mutable struct BasicObserver{M <: Metric} <: Observer{M}
    metric::M
end

struct BasicObservation{M <: Metric, D <: Any} <: Observation{M, D}
    metric::M
    interaction_id::String
    individual_ids::Vector{Int}
    data::D
end

end