module Domains

export DomainCfg

include("problems/problems.jl")

using ...CoEvo: Problem
using ...CoEvo: DomainConfiguration, PhenotypeConfiguration, ObservationConfiguration
using ..Observations: Observation, NullObs, NullObsCfg
using ..MatchMakers: MatchMaker, AllvsAllMatchMaker
using .Problems: NumbersGame, NumbersGameProblem

Base.@kwdef struct DomainCfg{
    P <: Problem, M <: MatchMaker, O <: ObservationConfiguration, 
} <: DomainConfiguration
    problem::P = NumbersGameProblem(:Sum)
    species_ids::Vector{String} = ["1", "2"]
    matchmaker::M = AllvsAllMatchMaker(:plus)
    obs_cfg::O = NullObsCfg()
end


end