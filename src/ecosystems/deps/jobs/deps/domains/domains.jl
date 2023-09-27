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
module Domains

# Exported Structures
export InteractiveDomainConfiguration

include("abstract/abstract.jl")

# Dependencies
include("deps/observers/observers.jl")
include("deps/settings/settings.jl")
include("deps/matchmakers/matchmakers.jl")
include("deps/reporters/reporters.jl")

# Imports
using ....CoEvo.Abstract: Problem, MatchMaker, ObservationConfiguration, DomainConfiguration
using ....CoEvo.Abstract: Reporter
using ...Observations: OutcomeObservationConfiguration
using .MatchMakers: MatchMaker, AllvsAllMatchMaker
using .Problems: NumbersGameProblem

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
Base.@kwdef struct InteractiveDomainCreator{
    S <: Setting, 
    M <: MatchMaker, 
    O <: Observer, 
    R <: Reporter
} <: DomainConfiguration
    id::String
    setting::S
    species_ids::Vector{String}
    matchmaker::M
    observers::Vector{O}
    reporters::Vector{R}
end

function create_domain(domain_creator::InteractiveDomainCreator)
    domain = create_domain(domain_creator.id, domain_creator.setting)
    return domain
end

end