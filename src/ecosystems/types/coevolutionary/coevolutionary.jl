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
using ...CoEvo.Abstract: AbstractSpecies, SpeciesConfiguration, Individual, Report
using ...CoEvo.Abstract: JobConfiguration, Observation, Reporter, Archiver, Evaluation 
using ...CoEvo.Utilities.Counters: Counter
using .Species.Evaluations: ScalarFitnessEvaluation
using .Reporters: RuntimeReport, RuntimeReporter
using .Archivers: DefaultArchiver

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

function Base.show(io::IO, eco::CoevolutionaryEcosystem)
    print(io, "Eco(id: ", eco.id, ", species: ", keys(eco.species), ")")
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
Base.@kwdef struct CoevolutionaryEcosystemConfiguration{
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
    archiver::A
    indiv_id_counter::Counter
    gene_id_counter::Counter
    runtime_reporter::R
end

function show(io::IO, c::CoevolutionaryEcosystemConfiguration)
    print(io, "CoevolutionaryEcosystemConfiguration(id: ", c.id, 
          ", trial: ", c.trial,
          ", rng: ", typeof(c.rng), 
          ", species: ", keys(c.species_cfgs), 
          ", domains: ", c.job_cfg.domain_cfgs,")")
end

function(eco_cfg::CoevolutionaryEcosystemConfiguration)()
    # Determine species IDs and populate species dictionary
    all_species = OrderedDict(
        species_id => species_cfg(
            eco_cfg.rng, 
            eco_cfg.indiv_id_counter, 
            eco_cfg.gene_id_counter
        ) 
        for (species_id, species_cfg) in eco_cfg.species_cfgs
    )

    return CoevolutionaryEcosystem(eco_cfg.id, all_species)
end




function get_outcomes(observations::Vector{<:Observation})
    # Initialize a dictionary to store interaction outcomes between individuals
    outcomes = Dict{Int, Dict{Int, Float64}}()

    for observation in observations 
        # Extract individual IDs and their respective outcomes from the interaction result
        indiv_id1, indiv_id2 = observation.indiv_ids
        outcome1, outcome2 = observation.outcome_set

        # Use `get!` to simplify dictionary insertion. 
        # If the key doesn't exist, a new dictionary is initialized and the outcome is recorded.
        get!(outcomes, indiv_id1, Dict{Int, Float64}())[indiv_id2] = outcome1
        get!(outcomes, indiv_id2, Dict{Int, Float64}())[indiv_id1] = outcome2
    end
    return outcomes
end

function get_all_indivs(eco::CoevolutionaryEcosystem)
    all_indivs = Dict{Int, Individual}(
        indiv.id => indiv 
        for species in values(eco.species) 
        for indiv in values(merge(species.pop, species.children))
    )
    return all_indivs
end

function filter_indivs(all_indivs::Dict{Int, Individual}, indiv_ids::Set{Int})
    return filter((indiv_id, indiv) -> indiv_id ∈ indiv_ids, all_indivs)
end


function(eco_cfg::CoevolutionaryEcosystemConfiguration)(
    gen::Int, 
    eco::Ecosystem, 
    observations::Vector{<:Observation}, 
    runtime_report::RuntimeReport
)
    outcomes = get_outcomes(observations)
    # Return the updated ecosystem configuration based on the interactions and observations
    all_new_species = Pair{String, AbstractSpecies}[]
    reports = Report[runtime_report]

    for (species_id, species) in eco.species
        species_cfg = eco_cfg.species_cfgs[species_id]

        pop_outcomes = Dict(
            indiv => outcomes[indiv.id] for indiv in values(species.pop)
        )
        pop_evals = species_cfg.eval_cfg(pop_outcomes)
        if length(species.pop) > 0
            for reporter in species_cfg.reporters
                push!(reports, reporter(gen, species_id, "Population", pop_evals))
            end
        end

        children_outcomes = Dict(
            indiv => outcomes[indiv.id] for indiv in values(species.children)
        )
        children_evals = species_cfg.eval_cfg(children_outcomes)

        if length(children_evals) > 0
            for reporter in species_cfg.reporters
                push!(reports, reporter(gen, species_id, "Children", children_evals))
            end
        end

        # new_species::Species
        new_species = species_cfg(
            eco_cfg.rng, 
            eco_cfg.indiv_id_counter, 
            eco_cfg.gene_id_counter, 
            pop_evals, 
            children_evals
        )
        push!(all_new_species, species_id => new_species)
    end
    all_new_species = OrderedDict(all_new_species)

    for (dom_id, dom_cfg) in eco_cfg.job_cfg.dom_cfgs
        observations = filter(obs -> obs.domain_id == dom_id, observations)
        for reporter in dom_cfg.reporters
            push!(reports, reporter(gen, dom_id, observations))
        end
    end

    [eco_cfg.archiver(report) for report in reports]

    return CoevolutionaryEcosystem(eco_cfg.id, all_new_species)
end


function evolve!(
    eco_cfg::CoevolutionaryEcosystemConfiguration;
    n_gen::Int = 100,
)
    eco = eco_cfg()
    last_reproduce_time = 0.0
    for gen in 1:n_gen
        eval_time_start = time()
        observations = eco_cfg.job_cfg(eco)
        eval_time = time() - eval_time_start
        runtime_report = eco_cfg.runtime_reporter(gen, eval_time, last_reproduce_time)

        last_reproduce_time_start = time()
        eco = eco_cfg(gen, eco, observations, runtime_report)
        last_reproduce_time = time() - last_reproduce_time_start
    end
    eco
end