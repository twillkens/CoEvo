"""
    Module Ecosystems

The top level module in CoEvo. Allows the user to define key parameters before starting 
the coevolutionary process.

# Structures:
- [`Eco`](#) : Represents the top-level object in the coevolutionary system.
- [`EcoCfg`](#) : Configuration object for setting up and managing ecosystems.

# Functions:
- [`EcoCfg(...)`](#) : Constructor function for generating ecosystem configurations.
- [`(eco_cfg::EcoCfg)()`](#) : A callable function to generate a new ecosystem based on its configuration.
- [`get_pheno_dict(...)`](#) : Extracts the phenotypes from individuals in the ecosystem.
- [`evolve!`](#) : Runs the evolution of the ecosystem for a set number of generations.

"""
module Ecosystems

export EcoCfg

include("archivists/archivists.jl")

using DataStructures
using ..CoEvo: Species, SpeciesConfiguration, JobConfiguration, Archivist, Individual, Ecosystem
using ..CoEvo: EcosystemConfiguration
using Random: AbstractRNG
using ..CoEvo.Utilities: Counter, next!
using StableRNGs: StableRNG
using .Archivists: DefaultArchivist

"""
    struct Eco <: Ecosystem

The top-level object in the coevolutionary system. Contains a collection 
of species, where each species has a population of individuals.

# Fields:
- `id`: A unique identifier for the ecosystem.
- `species`: A dictionary mapping species IDs to their respective species data.
"""
struct Eco <: Ecosystem
    id::String
    species::Dict{String, Species}
end

"""
    struct EcoCfg{
        S <: SpeciesConfiguration, 
        J <: JobConfiguration, 
        A <: Archivist
    } <: EcosystemConfiguration

Configuration object for setting up and managing ecosystems for coevolutionary runs.

# Fields:
- `id`: Identifier for the ecosystem configuration.
- `trial`: Trial number.
- `rng`: Random number generator.
- `species_cfgs`: List of species configurations.
- `job_cfg`: Job configuration.
- `archivist`: Specifies how the ecosystem data is archived.
- `indiv_id_counter`: Counter for individual IDs.
- `gene_id_counter`: Counter for gene IDs.
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

"""
    EcoCfg(
        species_cfgs::Vector{<:SpeciesConfiguration},
        job_cfg::JobConfiguration;
        id::String = "eco",
        trial::Int = 1,
        seed::Union{UInt64, Int} = -1,
        rng::Union{AbstractRNG, Nothing} = nothing,
        archivist::Archivist = DefaultArchivist(),
        indiv_id_counter::Counter = Counter(),
        gene_id_counter::Counter = Counter()
    ) -> EcoCfg

Construct an `EcoCfg` object to configure an ecosystem for a coevolutionary run.

# Arguments:
- `species_cfgs`: A list of configurations for each species in the ecosystem.
- `job_cfg`: Configuration related to the jobs/tasks in the ecosystem.

# Keyword Arguments:
- `id`: Identifier for the ecosystem configuration (default: "eco").
- `trial`: Trial number (default: 1).
- `seed`: Seed for the random number generator. If set to -1, a random seed will be chosen (default: -1).
- `rng`: Pre-configured random number generator. If `nothing`, it will be based on the seed (default: `nothing`).
- `archivist`: Specifies how the ecosystem data is archived (default: `DefaultArchivist()`).
- `indiv_id_counter`: Counter for individual IDs (default: starts at 0).
- `gene_id_counter`: Counter for gene IDs (default: starts at 0).

# Returns:
- An instance of `EcoCfg`.
"""
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

"""
    (eco_cfg::EcoCfg)() -> Eco

Generate a new ecosystem based on the given configuration `eco_cfg`.

# Arguments:
- `eco_cfg`: The configuration based on which the ecosystem will be generated.

# Returns:
- An instance of `Eco` which represents the generated ecosystem.

# Notes:
- If the first species configuration's ID is "default", species are enumerated. Otherwise, species use their respective configuration IDs.
"""
function(eco_cfg::EcoCfg)()
    if eco_cfg.species_cfgs[1].id == "default"
        species = OrderedDict(
            string(i) => species_cfg(
                eco_cfg.rng, eco_cfg.indiv_id_counter, eco_cfg.gene_id_counter
            ) 
            for (i, species_cfg) in enumerate(eco_cfg.species_cfgs)
        )
    else
        species = OrderedDict(
            species_cfg.id => species_cfg(
                eco_cfg.rng, eco_cfg.indiv_id_counter, eco_cfg.gene_id_counter
            ) for species_cfg in eco_cfg.species_cfgs
        )
    end

    Eco(eco_cfg.id, species)
end

"""
    get_pheno_dict(eco::Eco) -> Dict

Generate a dictionary that maps individual IDs to their respective phenotypes, based on the 
phenotype configuration of each species in the given ecosystem `eco`.

# Arguments:
- `eco`: The ecosystem instance containing the species and their respective individuals.

# Returns:
- A `Dict` where keys are individual IDs and values are the corresponding phenotypes.

# Notes:
- This function fetches phenotypes for both the current population (`pop`) and the offspring (`children`) 
  for each species in the ecosystem.
"""
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