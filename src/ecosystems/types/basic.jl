export BasicEcosystem, BasicEcosystemCreator
export evolve!

using Random: AbstractRNG
using StableRNGs: StableRNG
using DataStructures: OrderedDict

using .Abstract: Ecosystem, EcosystemCreator, Report, Reporter
using .Utilities.Counters: Counter
using .Species.Abstract: AbstractSpecies, SpeciesCreator
using .Species.Individuals.Abstract: Individual, IndividualCreator
using .Jobs.Abstract: JobCreator, Result
using .Jobs.Interactions.Observers.Abstract: Observation
using .Reporters: RuntimeReport, RuntimeReporter
using .Archivers.Abstract: Archiver

struct BasicEcosystem{S <: AbstractSpecies} <: Ecosystem
    id::String
    species::OrderedDict{String, S}
end

function Base.show(io::IO, eco::BasicEcosystem)
    print(io, "Eco(id: ", eco.id, ", species: ", keys(eco.species), ")")
end


"""
    struct EcoCfg{
        S <: SpeciesCreator, 
        J <: JobCreator, 
        A <: Archiver
    } <: EcosystemCreator

Creator object for setting up and managing ecosystems for coevolutionary runs.

# Fields:
- `id`: Identifier for the ecosystem configuration.
- `trial`: Trial number.
- `rng`: Random number generator.
- `species_creators`: List of species configurations.
- `job_creator`: Job configuration.
- `archiver`: Specifies how the ecosystem data is archived.
- `indiv_id_counter`: Counter for individual IDs.
- `gene_id_counter`: Counter for gene IDs.
"""
Base.@kwdef struct BasicEcosystemCreator{
    S <: SpeciesCreator, 
    J <: JobCreator, 
    R <: Reporter,
    A <: Archiver,
} <: EcosystemCreator
    id::String
    trial::Int
    rng::AbstractRNG
    species_creators::Dict{String, S}
    job_creator::J
    archiver::A
    indiv_id_counter::Counter
    gene_id_counter::Counter
    runtime_reporter::R
end

function show(io::IO, c::BasicEcosystemCreator)
    print(io, "BasicEcosystemCreator(id: ", c.id, 
          ", trial: ", c.trial,
          ", rng: ", typeof(c.rng), 
          ", species: ", keys(c.species_creators), 
          ", domains: ", c.job_creator.domain_creators,")")
end

function create_ecosystem(eco_creator::BasicEcosystemCreator)
    # Determine species IDs and populate species dictionary
    all_species = Dict(
        species_id => species_creator(
            eco_creator.rng, 
            eco_creator.indiv_id_counter, 
            eco_creator.gene_id_counter
        ) 
        for (species_id, species_creator) in eco_creator.species_creators
    )

    return BasicEcosystem(eco_creator.id, all_species)
end

function create_ecosystem(
    gen::Int, 
    eco_creator::BasicEcosystemCreator,
    eco::Ecosystem, 
    results::Vector{<:Result}, 
    runtime_report::Report
)
    observations = extract_observations(results)
    reports = Report[runtime_report]
    
    append!(reports, process_domain_reports(gen, eco_creator, observations))
    
    species_evaluations = evaluate_species(eco_creator, eco, results)
    append!(reports, generate_species_reports(gen, eco_creator, species_evaluations))
    
    archive_reports(eco_creator, reports)
    all_new_species = construct_new_species(eco_creator, species_evaluations)
    
    return BasicEcosystem(eco_creator.id, all_new_species)
end

function extract_observations(results::Vector{<:Result})
    return [observation for result in results for observation in result.observations]
end

function process_domain_reports(gen::Int, eco_creator::BasicEcosystemCreator, observations)
    reports = Report[]
    for (domain_id, scheme) in eco_creator.job_creator.domain_creators
        filtered_observations = filter(obs -> obs.domain_id == domain_id, observations)
        for reporter in scheme.reporters
            push!(reports, reporter(gen, domain_id, filtered_observations))
        end
    end
    return reports
end
"""
    get_outcomes(observations::Vector{<:Observation})

Extracts and organizes interaction outcomes between pairs of individuals from a given set of 
observations.

# Arguments
- `observations::Vector{<:Observation}`: A vector of observations, where each observation typically captures the outcomes of interactions for specific pairs of individuals.

# Returns
- A dictionary where the primary keys are individual IDs. The value associated with each individual ID is another dictionary. In this inner dictionary, the keys are IDs of interacting partners, and the values are the outcomes of the interactions.
"""
function get_outcomes(results::Vector{<:Result})
    # Initialize a dictionary to store interaction outcomes between individuals
    outcomes = Dict{Int, Dict{Int, Float64}}()

    for result in results 
        # Extract individual IDs and their respective outcomes from the interaction result
        indiv_id1, indiv_id2 = result.indiv_ids
        outcome1, outcome2 = result.outcome_set

        # Use `get!` to simplify dictionary insertion. 
        # If the key doesn't exist, a new dictionary is initialized and the outcome is recorded.
        get!(outcomes, indiv_id1, Dict{Int, Float64}())[indiv_id2] = outcome1
        get!(outcomes, indiv_id2, Dict{Int, Float64}())[indiv_id1] = outcome2
    end
    return outcomes
end

function evaluate_species(
    eco_creator::BasicEcosystemCreator,
    eco::Ecosystem, 
    results::Vector{<:Result}
)
    evaluations = Dict{String, Dict{String, Evaluation}}()
    outcomes = get_outcomes(results)
    
    for (species_id, species) in eco.species
        species_creator = eco_creator.species_creators[species_id]
        evaluations[species_id] = Dict(
            "Population" => species_creator.indiv_creator.eval_creator(
                Dict(indiv => outcomes[indiv.id] for indiv in values(species.pop))
            ),
            "Children" => species_creator.indiv_creator.eval_creator(
                Dict(indiv => outcomes[indiv.id] for indiv in values(species.children))
            )
        )
    end
    
    return evaluations
end

function generate_species_reports(gen::Int, eco_creator::BasicEcosystemCreator, evaluations)
    reports = Report[]
    
    for (species_id, species_eval) in evaluations
        species_creator = eco_creator.species_creators[species_id]
        
        for (cohort, evals) in species_eval
            for reporter in species_creator.reporters
                push!(reports, reporter(gen, species_id, cohort, evals))
            end
        end
    end
    
    return reports
end

function archive_reports(eco_creator::BasicEcosystemCreator, reports)
    [eco_creator.archiver(report) for report in reports]
end

function construct_new_species(eco_creator::BasicEcosystemCreator, evaluations)
    all_new_species = Pair{String, AbstractSpecies}[]
    
    for (species_id, species_eval) in evaluations
        species_creator = eco_creator.species_creators[species_id]
        new_species = species_creator(
            eco_creator.rng, 
            eco_creator.indiv_id_counter, 
            eco_creator.gene_id_counter, 
            species_eval["Population"], 
            species_eval["Children"]
        )
        push!(all_new_species, species_id => new_species)
    end
    
    return Dict(all_new_species)
end



function evolve!(
    eco_creator::BasicEcosystemCreator;
    n_gen::Int = 100,
)
    eco = create_ecosystem(eco_creator)
    last_reproduce_time = 0.0
    for gen in 1:n_gen
        eval_time_start = time()
        observations = eco_creator.job_creator(eco)
        eval_time = time() - eval_time_start
        runtime_report = eco_creator.runtime_reporter(gen, eval_time, last_reproduce_time)

        last_reproduce_time_start = time()
        eco = create_ecosystem(gen, eco_creator, eco, observations, runtime_report)
        last_reproduce_time = time() - last_reproduce_time_start
    end
    eco
end