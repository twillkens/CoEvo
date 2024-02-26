
module DensityClassification

export DensityClassificationDomain, Covers

import ....Interfaces: measure

using Base: @kwdef
using ....Abstract: Metric, Domain

struct DensityClassificationDomain{M <: Metric} <: Domain{M}
    outcome_metric::M
end

function get_majority_value(values::Vector{Int})
    sum(values) > length(values) / 2 ? 1 : 0
end

@kwdef struct Covers <: Metric 
    name::String = "Covers"
end

function measure(
    ::DensityClassificationDomain{Covers}, 
    initial_condition::Vector{Int}, 
    final_state::Vector{Int}
)
    maj_value = get_majority_value(initial_condition)
    # Check if the final state has "relaxed" to a uniform state matching the majority value
    if all(x -> x == maj_value, final_state)
        return [1.0, 0.0]  # The system has relaxed to the expected majority state
    else
        return [0.0, 1.0]  # The system has not relaxed to the expected majority state
    end

end

function measure(domain::DensityClassificationDomain{Covers}, states::Matrix{Int})
    initial_condition = states[1, :]
    final_state = states[end, :]
    outcomes = measure(domain, initial_condition, final_state)
    return outcomes
end


function DensityClassificationDomain(metric_string::String)
    string_to_metric = Dict(
        "Covers" => Covers,
    )
    outcome_metric = string_to_metric[metric_string]()
    domain = DensityClassificationDomain(outcome_metric)
    return domain
end

end