module Ecosystems

export EcoCfg

include("archivists/archivists.jl")

using ..CoEvo: Species, SpeciesConfiguration, JobConfiguration, Archivist, Individual, Ecosystem
using ..CoEvo: EcosystemConfiguration
using Random: AbstractRNG
using ..CoEvo.Utilities: Counter
using StableRNGs: StableRNG
using .Archivists: DefaultArchivist

# The top-level object in the coevolutionary system. It contains a
# collection of species, each of which contains a population of individuals.
struct Eco <: Ecosystem
    id::String
    species::Dict{String, Species}
end

"""
    EcosystemCfg{
        S <: Spawner,
        O <: Order,
        J <: JobConfiguration,
        A <: Archivist
    }

    Create an ecosystem configuration for a coevolutionary run. 
"""

struct EcoCfg{
    S <: SpeciesConfiguration, 
    J <: JobConfiguration, 
    A <: Archivist
} <: EcosystemConfiguration
    id::String
    trial::Int
    rng::AbstractRNG
    species_cfgs::Vector{S}
    job_cfg::J
    archivist::A
    indiv_id_counter::Counter
    gene_id_counter::Counter
end

function EcoCfg(
    species_cfgs::Vector{<:SpeciesConfiguration},
    job_cfg::JobConfiguration;
    id::String = "eco",
    trial::Int = 1,
    seed::Union{UInt64, Int} = -1,
    rng::Union{AbstractRNG, Nothing} = nothing,
    archivist::Archivist = DefaultArchivist(),
    indiv_id_counter::Counter = Counter(),
    gene_id_counter::Counter = Counter(),
)
    rng = rng !== nothing ? rng : seed == -1 ? StableRNG(rand(UInt32)) : StableRNG(seed)
    EcoCfg(
        id, trial, rng, species_cfgs, job_cfg, archivist, indiv_id_counter, gene_id_counter
    )
end

# Generate a new ecosystem from the configuration.
function(eco_cfg::EcoCfg)()
    if eco_cfg.species_cfgs[1].id == ""
        species = Dict(
            string(i) => species_cfg() for (i, species_cfg) in enumerate(eco_cfg.species_cfgs)
        )
    else
        species = Dict(
            species_cfg.id => species_cfg() for species_cfg in eco_cfg.species_cfgs
        )
    end

    Eco(eco_cfg.id, species)
end

# Use the phenotype configuration for each species to generate a dictionary mapping 
# individual ids to phenotypes.
function get_pheno_dict(eco::Eco)
    Dict(
        indiv_id => species.pheno_cfg(indiv_id, indiv.geno)
        for (indiv_id, indiv) in merge(species.pop, species.children)
        for species in values(eco.species)
    )
end

function evolve!(
    eco_cfg::EcoCfg;
    n_gen::Int = 100,
)
    eco = eco_cfg()

    for gen in 1:n_gen
        println("Generation $gen")
        results = eco_cfg.job_cfg(eco)
        eco, evaluations = eco_cfg(eco, results)
        #eco_cfg.archivist(eco, evaluations, results)
    end
    eco
end

end