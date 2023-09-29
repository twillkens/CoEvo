module Basic

export BasicDomain

using ..Abstract: Domain
using ..Domains.Abstract: DomainCreator
using ..MatchMakers.Abstract: MatchMaker
using ..Observers.Abstract: Observer
using ..Reporters.Abstract: Reporter

"""
    InteractiveDomainConfiguration{P <: Problem, M <: MatchMaker, O <: ObservationConfiguration, R <: Reporter}

Represents a configuration for an interactive domain. It comprises various components like 
problem definition, matchmaker mechanism, observation configurations, and reporters.

# Fields
- `id::String`: A unique identifier for the domain configuration. Default is "1".
- `problem::P`: Specifies the type of problem in the domain. Default is `NumbersGameProblem(:Sum)`.
- `species_ids::Vector{String}`: IDs of the species involved in the domain. Default is `["1", "2"]`.
- `matchmaker::M`: Defines the matching mechanism in the domain. Default is `AllvsAllMatchMaker(:plus)`.
- `obs_cfg::O`: Configuration related to observations within the domain. Default is `OutcomeObservationConfiguration()`.
- `reporters::Vector{R}`: A list of reporters for logging and reporting activities within the domain. Default is `Reporter[]`.
"""
Base.@kwdef struct BasicDomain <: Domain{
    E <: EnvironmentCreator, 
    M <: MatchMaker, 
    O <: Observer, 
    R <: Reporter
} 
    id::String
    env_creator::E
    species_ids::Vector{String}
    matchmaker::M
    observers::Vector{O}
    reporters::Vector{R}
end

end