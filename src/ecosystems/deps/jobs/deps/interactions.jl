"""
    Domains

The `Domains` module provides structures and functionality associated with 
interactive domains. It brings together problems, matchmakers, observation configurations,
and reporters to facilitate interactive domain configuration.

# Structures
- `InteractiveDomainConfiguration`: Represents the configuration of an interactive domain.

# Dependencies
- `Problems`: Contains different types of problems that the domain can work with.
- `MatchMakers`: Provides mechanisms for creating matchings in the domain.
- `Reporters`: Allows for reporting and logging activities within the domain.
"""
module Interactions

# Exported Structures
export InteractionScheme
export DomainCreator, MatchMakers, Observers, Reporters, Domains

# Dependencies
include("interactions/domains/domains.jl")
include("interactions/matchmakers/matchmakers.jl")
include("interactions/observers/observers.jl")
include("interactions/reporters/reporters.jl")

# Imports
using .Domains.Abstract: DomainCreator
using .MatchMakers.Abstract: MatchMaker
using .Observers.Abstract: Observer
using .Reporters.Abstract: Reporter
using .Observers: Observers
using .Domains: Domains
using .MatchMakers: MatchMakers
using .Reporters: Reporters

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
Base.@kwdef struct InteractionScheme{
    D <: DomainCreator, 
    M <: MatchMaker, 
    O <: Observer, 
    R <: Reporter
} 
    id::String
    domain_creator::D
    species_ids::Vector{String}
    matchmaker::M
    observers::Vector{O}
    reporters::Vector{R}
end

end