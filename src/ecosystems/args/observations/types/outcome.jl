export OutcomeObservation, OutcomeObservationConfiguration

using ...CoEvo.Abstract: Observation, ObservationConfiguration, Problem

Base.@kwdef struct OutcomeObservationConfiguration <: ObservationConfiguration end

# domain_id, indiv_set, and outcome_set are required fields for the Observation type
struct OutcomeObservation <: Observation
    domain_id::String
    indiv_ids::Vector{Int}
    outcome_set::Vector{Float64}
end

function (obs_cfg::OutcomeObservationConfiguration)(
    ::Problem,
    domain_id::String, 
    indiv_ids::Vector{Int}, 
    outcome_set::Vector{Float64},
    args...;
    kwargs...
)
    return OutcomeObservation(domain_id, indiv_ids, outcome_set)
end