
using ....CoEvo.Abstract: Problem, MatchMaker, ObservationConfiguration, DomainConfiguration
using ...Observations: OutcomeObservationConfiguration
using .MatchMakers: MatchMaker, AllvsAllMatchMaker
using .Problems: NumbersGameProblem


Base.@kwdef struct InteractiveDomainConfiguration{
    P <: Problem, M <: MatchMaker, O <: ObservationConfiguration, 
} <: DomainConfiguration
    id::String = "1"
    problem::P = NumbersGameProblem(:Sum)
    species_ids::Vector{String} = ["1", "2"]
    matchmaker::M = AllvsAllMatchMaker(:plus)
    obs_cfg::O = OutcomeObservationConfiguration()
end