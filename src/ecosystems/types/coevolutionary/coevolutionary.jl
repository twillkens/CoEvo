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

export CoevolutionaryEcosystem, CoevolutionaryEcosystemConfiguration
export evolve!

using Random: AbstractRNG
using StableRNGs: StableRNG
using DataStructures: OrderedDict
using ...CoEvo.Abstract: Ecosystem, EcosystemConfiguration
using ...CoEvo.Abstract: AbstractSpecies, SpeciesConfiguration
using ...CoEvo.Abstract: JobConfiguration, Observation, Reporter, Archiver
using .Species.Utilities: Counter
using .Reporters: RuntimeRepor, FitnessReporter
using .Archivers: NullArchiver

"""
    struct Eco <: Ecosystem

The top-level object in the coevolutionary system. Contains a collection 
of species, where each species has a population of individuals.

# Fields:
- `id`: A unique identifier for the ecosystem.
- `species`: A dictionary mapping species IDs to their respective species data.
"""
struct CoevolutionaryEcosystem{S <: AbstractSpecies} <: Ecosystem
    id::String
    species::OrderedDict{String, S}
end

"""
    struct EcoCfg{
        S <: SpeciesConfiguration, 
        J <: JobConfiguration, 
        A <: Archiver
    } <: EcosystemConfiguration

Configuration object for setting up and managing ecosystems for coevolutionary runs.

# Fields:
- `id`: Identifier for the ecosystem configuration.
- `trial`: Trial number.
- `rng`: Random number generator.
- `species_cfgs`: List of species configurations.
- `job_cfg`: Job configuration.
- `archiver`: Specifies how the ecosystem data is archived.
- `indiv_id_counter`: Counter for individual IDs.
- `gene_id_counter`: Counter for gene IDs.
"""
struct CoevolutionaryEcosystemConfiguration{
    S <: SpeciesConfiguration, 
    J <: JobConfiguration, 
    R <: Reporter,
    A <: Archiver,
} <: EcosystemConfiguration
    id::String
    trial::Int
    rng::AbstractRNG
    species_cfgs::OrderedDict{String, S}
    job_cfg::J
    reporters::Vector{R}
    archiver::A
    indiv_id_counter::Counter
    gene_id_counter::Counter
    log_runtime::Bool
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
function CoevolutionaryEcosystemConfiguration(
    species_cfgs::Vector{<:SpeciesConfiguration},
    job_cfg::JobConfiguration;
    id::String = "default",
    trial::Int = 1,
    seed::Union{UInt64, Int} = -1,
    rng::Union{AbstractRNG, Nothing} = nothing,
    reporters::Vector{<:Reporter} = [FitnessReporter()],
    archiver::Archiver = NullArchiver(),
    indiv_id_counter::Counter = Counter(),
    gene_id_counter::Counter = Counter(),
)
    rng = rng !== nothing ? rng : seed == -1 ? StableRNG(rand(UInt32)) : StableRNG(seed)
    species_cfgs = OrderedDict(
        "default" in map(species_cfg -> species_cfg.id, species_cfgs) ? 
            string(i) => species_cfg : 
            species_cfg.id => species_cfg 
        for (i, species_cfg) in enumerate(species_cfgs)
    )
    CoevolutionaryEcosystemConfiguration(
        id, 
        trial, 
        rng, 
        species_cfgs, 
        job_cfg, 
        reporters,
        archiver,
        indiv_id_counter, 
        gene_id_counter
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
function(eco_cfg::CoevolutionaryEcosystemConfiguration)()

    # Helper function to create species based on configuration
    function create_species(species_cfg)
        return species_cfg(
            eco_cfg.rng, eco_cfg.indiv_id_counter, eco_cfg.gene_id_counter
        )
    end

    # Determine species IDs and populate species dictionary
    all_species = OrderedDict(
        species_id => create_species(species_cfg) 
        for (species_id, species_cfg) in eco_cfg.species_cfgs
    )

    return CoevolutionaryEcosystem(eco_cfg.id, all_species)
end




function get_outcomes(all_indivs::Dict{Int, <:Individual}, observations::Vector{<:Observation})
    # Initialize a dictionary to store interaction outcomes between individuals
    outcomes = Dict{Individual, Dict{Individual, Float64}}()

    for observation in observations 
        # Extract individual IDs and their respective outcomes from the interaction result
        indiv_id1, indiv_id2 = observation.indiv_ids
        indiv1, indiv2 = all_indivs[indiv_id1], all_indivs[indiv_id2]
        outcome1, outcome2 = observation.outcome_set

        # Use `get!` to simplify dictionary insertion. 
        # If the key doesn't exist, a new dictionary is initialized and the outcome is recorded.
        get!(outcomes, indivd1, Dict{Individual, Float64}())[indiv2] = outcome1
        get!(outcomes, indivd2, Dict{Individual, Float64}())[indiv1] = outcome2
    end
    outcomes
end

function get_all_indivs(eco::CoevolutionaryEcosystem)
    all_indivs = Dict(
        indiv_id => indiv 
        for species in values(eco.species) 
        for indiv in values(merge(species.pop, species.children))
    )
    return all_indivs
end

function filter_indivs(all_indivs::Dict{Int, <:Individual}, indiv_ids::Set{Int})
    return filter((indiv_id, indiv) -> indiv_id ∈ indiv_ids, all_indivs)
end


function(eco_cfg::CoevolutionaryEcosystemConfiguration)(
    gen::Int, 
    eco::Ecosystem, 
    observations::Vector{<:Observation}, 
    eval_time::Float64,
    reproduce_time::Float64,
)
    # Type of all_indivs is Dict{Int, <:Individual}
    all_indivs = get_all_indivs(eco)
    # Type of outcomes is Dict{Individual, Dict{Individual, Float64}}
    outcomes = get_outcomes(all_indivs, observations)
    # Return the updated ecosystem configuration based on the interactions and observations
    all_new_species = Pair{String, <:Species}[]
    species_pop_evals = Pair{String, OrderedDict{<:Individual, <:Evaluation}}[]
    species_children_evals = Pair{String, OrderedDict{<:Individual, <:Evaluation}}[]

    for (species_id, species) in eco.species
        species_cfg = eco_cfg.species_cfgs[species_id]
        pop_outcomes = filter(
            (indiv, outcome) -> indiv.id ∈ keys(species.pop), outcomes
        )
        children_outcomes = filter(
            (indiv, outcome) -> indiv.id ∈ keys(species.children), outcomes
        )
        # pop_evals::OrderedDict{<:Individual, <:Evaluation}
        pop_evals = species_cfg.eval_cfg(pop_outcomes)
        # children_evals::OrderedDict{<:Individual, <:Evaluation}
        children_evals = species_cfg.eval_cfg(children_outcomes)
        # new_species::Species
        new_species = species_cfg(
            eco_cfg.rng, 
            eco_cfg.indiv_id_counter, 
            eco_cfg.gene_id_counter, 
            pop_evals, 
            children_evals
        )
        push!(all_new_species, species_id => new_species)
        push!(species_pop_evals, species_id => pop_evals)
        push!(species_children_evals, species_id => children_evals)
    end
    all_new_species = OrderedDict(all_new_species)
    species_pop_evals = OrderedDict(species_pop_evals)
    species_children_evals = OrderedDict(species_children_evals)

    all_observations = []
    for dom_id in keys(eco_cfg.job_cfg.dom_cfgs)
        domain_observations = filter(
            obs -> obs.dom_id == dom_id, observations
        )
        push!(all_observations, dom_id => domain_observations)
    end

    reports = [
        reporter(
            gen = gen,
            eval_time = eval_time,
            reproduce_time = reproduce_time,
            species_pop_evals = species_pop_evals, 
            species_children_evals = species_children_evals, 
            domain_observations = domain_observations,
        ) 
        for reporter in eco_cfg.reporters
    ]


    eco_cfg.archiver(all_pop_evals, all_children_evals, reports)

    return CoevolutionaryEcosystem(eco_cfg.id, all_new_species)
end


function evolve!(
    eco_cfg::CoevolutionaryEcosystemConfiguration;
    n_gen::Int = 100,
)
    eco = eco_cfg()
    reproduce_time = 0.0
    for gen in 1:n_gen
        eval_time_start = time()
        observations = eco_cfg.job_cfg(eco)
        eval_time = time() - eval_time_start
        runtime_report = RuntimeReport()

        reproduce_time_start = time()
        eco = eco_cfg(gen, eco, observations, eval_time, reproduce_time)
        reproduce_time = time() - reproduce_time_start
    end
    eco
end