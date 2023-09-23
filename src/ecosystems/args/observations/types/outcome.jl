using ...CoEvo.Abstract: Observation, ObservationConfiguration

Base.@kwdef struct OutcomeObservationConfiguration <: ObservationConfiguration end

# domain_id, indiv_set, and outcome_set are required fields for the Observation type
struct OutcomeObservation <: Observation
    domain_id::Int
    indiv_ids::Vector{Int}
    outcome_set::Vector{Float64}
end
