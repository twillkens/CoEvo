module Domains

using ...CoEvo: Problem, Ecosystem
using ...CoEvo: DomainConfiguration, PhenotypeConfiguration, ObservationConfiguration
using ..Observations: Observation, NullObs, NullObsCfg
using ..MatchMakers: MatchMaker, AllvsAllMatchMaker

export DomainCfg

Base.@kwdef struct DomainCfg{
    P <: Problem, M <: MatchMaker, PC <: PhenotypeConfiguration, O <: ObservationConfiguration, 
} <: DomainConfiguration
    problem::P
    species_ids::Vector{String}
    matchmaker::M = AllvsAllMatchMaker(:plus)
    obs_cfg::O = NullObsCfg()
end

struct InteractionRecipe
    domain_id::Int
    indiv_ids::Vector{Int}
end

struct InteractionResult{O <: Observation}
    domain_id::Int
    indiv_ids::Vector{Int}
    outcome_set::Vector{Float64}
    observation::O
end

 InteractionResult(domain_id::Int, indiv_ids::Vector{Int}, outcome_set::Vector{Float64}) =
    InteractionResult(domain_id, indiv_ids, outcome_set, NullObs())

function make_interaction_recipes(domain_id::Int, cfg::DomainCfg, eco::Ecosystem)
    if length(cfg.entities) != 2
        throw(ArgumentError("Only two-entity interactions are supported for now."))
    end
    species1 = eco.species[cfg.pheno_ids[1]]
    species2 = eco.species[cfg.pheno_ids[2]]
    interaction_ids = cfg.matchmaker(species1, species2)
    interaction_recipes = [
        InteractionRecipe(domain_id, [id1, id2]) for (id1, id2) in interaction_ids
    ]
    return interaction_recipes
end

end