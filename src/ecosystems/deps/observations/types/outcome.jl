"""
    Observations

This module provides the `OutcomeObservation` type and its associated configuration, 
allowing for the capture and structure of outcomes from interactions in coevolutionary processes.

# Structs
- [`OutcomeObservation`](@ref): Captures specific outcomes from interactions.
- [`OutcomeObservationConfiguration`](@ref): Configuration for the creation of an `OutcomeObservation`.

# Functions
- A constructor-like callable function for the `OutcomeObservationConfiguration` type.
"""

export OutcomeObservation, OutcomeObservationConfiguration

using ...CoEvo.Abstract: Observation, ObservationConfiguration, Problem


"""
    OutcomeObservation <: Observation

A type that captures outcomes of interactions for a specific domain and set of individuals.

# Fields
- `domain_id::String`: An identifier for the domain in which the observation took place.
- `indiv_ids::Vector{Int}`: A vector of integer IDs representing the individuals involved in the observation.
- `outcome_set::Vector{Float64}`: A vector of outcomes (as floating-point numbers) corresponding to the interactions or evaluations of the specified individuals.
"""
struct OutcomeObservation <: Observation
    domain_id::String
    indiv_ids::Vector{Int}
    outcome_set::Vector{Float64}
end

"""
    OutcomeObservationConfiguration <: ObservationConfiguration

A struct defining the configuration for creating an `OutcomeObservation`. Currently, it doesn't 
specify any additional configuration fields.

# Usage
This configuration can be used as a callable to facilitate the creation of an `OutcomeObservation`.
"""
Base.@kwdef struct OutcomeObservationConfiguration <: ObservationConfiguration end

"""
    (obs_cfg::OutcomeObservationConfiguration)(::Problem, domain_id::String, indiv_ids::Vector{Int}, outcome_set::Vector{Float64}, args...; kwargs...)

A constructor-like callable function for the `OutcomeObservationConfiguration` type. 
When called, it returns an `OutcomeObservation` for the specified domain, set of individuals, 
and outcomes.

# Arguments
- `::Problem`: The specific problem or task context. Currently, this isn't used in the function but may be relevant for extended functionality.
- `domain_id::String`: Identifier for the domain.
- `indiv_ids::Vector{Int}`: IDs of the involved individuals.
- `outcome_set::Vector{Float64}`: Outcomes corresponding to the individuals.

# Returns
- An instance of `OutcomeObservation`.
"""
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