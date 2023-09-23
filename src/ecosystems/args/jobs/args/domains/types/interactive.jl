
using ....CoEvo.Abstract: Problem, MatchMaker, ObservationConfiguration, DomainConfiguration
using ...Observations: OutcomeObservationConfiguration
using .MatchMakers: MatchMaker, AllvsAllMatchMaker
using .Problems: NumbersGameProblem

# Constructor for InteractionResult with a default observation type.
InteractionResult(domain_id::Int, indiv_ids::Vector{Int}, outcome_set::Vector{Float64}) =
    InteractionResult(domain_id, indiv_ids, outcome_set, NullObs())

"""
    DomainCfg{
        P <: Problem, 
        M <: MatchMaker, 
        O <: ObservationConfiguration
    } <: DomainConfiguration

Configuration structure for defining the interactive domain of a simulation or experiment.

# Fields:
- `problem::P`: Specifies the particular problem posed within the domain.
                Defaults to a NumbersGameProblem{Sum}.
- `species_ids::Vector{String}`: IDs of species participating in the domain.
                                Defaults to two species with IDs "1" and "2".
- `matchmaker::M`: Strategy for deciding how species interact.
                   Defaults to a matchmaker that pairs all entities with one another.
- `obs_cfg::O`: Configuration for how observations are taken during interactions.
                Defaults to a configuration that produces null observations.

# Types:
- `P`: A subtype of `Problem`, defining the kind of problem used in the domain.
- `M`: A subtype of `MatchMaker`, defining the matchmaking strategy.
- `O`: A subtype of `ObservationConfiguration`, defining the observation strategy.
"""
Base.@kwdef struct InteractiveDomainConfiguration{
    P <: Problem, M <: MatchMaker, O <: ObservationConfiguration, 
} <: DomainConfiguration
    id::String = "1"
    problem::P = NumbersGameProblem(:Sum)
    species_ids::Vector{String} = ["1", "2"]
    matchmaker::M = AllvsAllMatchMaker(:plus)
    obs_cfg::O = OutcomeObservationConfiguration()
end