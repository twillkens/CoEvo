
export CoevolutionaryEcosystem, CoevolutionaryEcosystemConfiguration
export evolve!

using Random: AbstractRNG
using StableRNGs: StableRNG
using DataStructures: OrderedDict

using ..Abstract: Ecosystem, EcosystemConfiguration
using ..Abstract: AbstractSpecies, SpeciesConfiguration
using ..Abstract: Individual
using ..Abstract: JobConfiguration
using ..Abstract: Observation
using ..Abstract: Report, Reporter
using ..Abstract: Archiver

using ..Utilities.Counters: Counter

using .Reporters: RuntimeReport, RuntimeReporter
using .Observations: get_outcomes



struct CoevolutionaryEcosystem{S <: AbstractSpecies} <: Ecosystem
    id::String
    species::OrderedDict{String, S}
end

function Base.show(io::IO, eco::CoevolutionaryEcosystem)
    print(io, "Eco(id: ", eco.id, ", species: ", keys(eco.species), ")")
end

function get_all_indivs(eco::CoevolutionaryEcosystem)
    all_indivs = Dict{Int, Individual}(
        indiv.id => indiv 
        for species in values(eco.species) 
        for indiv in values(merge(species.pop, species.children))
    )
    return all_indivs
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