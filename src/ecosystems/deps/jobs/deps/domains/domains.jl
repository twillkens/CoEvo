
module Domains

export InteractiveDomainConfiguration

include("deps/problems/problems.jl")
include("deps/matchmakers/matchmakers.jl")
include("deps/reporters/reporters.jl")

using ....CoEvo.Abstract: Problem, MatchMaker, ObservationConfiguration, DomainConfiguration
using ....CoEvo.Abstract: Reporter
using ...Observations: OutcomeObservationConfiguration
using .MatchMakers: MatchMaker, AllvsAllMatchMaker
using .Problems: NumbersGameProblem


Base.@kwdef struct InteractiveDomainConfiguration{
    P <: Problem, 
    M <: MatchMaker, 
    O <: ObservationConfiguration, 
    R <: Reporter
} <: DomainConfiguration
    id::String # = "1"
    problem::P # = NumbersGameProblem(:Sum)
    species_ids::Vector{String} # = ["1", "2"]
    matchmaker::M # = AllvsAllMatchMaker(:plus)
    obs_cfg::O # = OutcomeObservationConfiguration()
    reporters::Vector{R} # = Reporter[]
end

end