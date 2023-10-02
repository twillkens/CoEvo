module Basic

export BasicEcosystem, BasicEcosystemCreator
export evolve!

using Random: AbstractRNG
using StableRNGs: StableRNG
using DataStructures: OrderedDict

using ..Abstract: Ecosystem, EcosystemCreator
using ..Utilities.Counters: Counter
using ..Species.Abstract: AbstractSpecies, SpeciesCreator
using ..Species.Interfaces: create_species
using ..Species.Individuals: Individual
using ..Species.Evaluators.Abstract: Evaluation
using ..Species.Evaluators.Interfaces: create_evaluation
using ..Jobs.Abstract: JobCreator
using ..Performers.Abstract: Performer
using ..Interactions.Results: Result, get_indiv_outcomes, get_observations
using ..Interactions.Observers.Abstract: Observation
using ..Reporters.Runtime: RuntimeReporter, create_runtime_report
using ..Reporters.Abstract: Reporter, Report
using ..Reporters.Interfaces: create_reports
using ..Archivers.Abstract: Archiver
using  ..Jobs.Interfaces: create_jobs
using ..Performers.Interfaces: perform

import ..Ecosystems.Interfaces: create_ecosystem, evolve!


struct BasicEcosystem{S <: AbstractSpecies} <: Ecosystem
    id::String
    species::OrderedDict{String, S}
end

function Base.show(io::IO, eco::BasicEcosystem)
    print(io, "Eco(id: ", eco.id, ", species: ", keys(eco.species), ")")
end

Base.@kwdef struct BasicEcosystemCreator{
    S <: SpeciesCreator, 
    J <: JobCreator, 
    P <: Performer,
    R <: Reporter,
    A <: Archiver,
} <: EcosystemCreator
    id::String
    trial::Int
    rng::AbstractRNG
    species_creators::Dict{String, S}
    job_creator::J
    performer::P
    reporters::Vector{R}
    archiver::A
    indiv_id_counter::Counter
    gene_id_counter::Counter
    runtime_reporter::RuntimeReporter = RuntimeReporter()
end

function show(io::IO, c::BasicEcosystemCreator)
    print(io, "BasicEcosystemCreator(id: ", c.id, 
          ", trial: ", c.trial,
          ", rng: ", typeof(c.rng), 
          ", species: ", keys(c.species_creators), 
          ", interactions: ", c.job_creator.interactions,")")
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
    eco = BasicEcosystem(eco_creator.id, all_species)

    return eco
end


function evaluate_species(
    eco_creator::BasicEcosystemCreator,
    eco::Ecosystem, 
    results::Vector{<:Result}
)
    indiv_outcomes = get_indiv_outcomes(results)

    species_evaluations = Dict(
        species => create_evaluation(
            eco_creator.species_creators[species_id].evaluator,
            species, 
            indiv_outcomes
        ) 
        for (species_id, species) in eco.species
    )
    
    return species_evaluations
end

function create_all_reports(
    gen::Int, 
    reporters::Vector{<:Reporter}, 
    species_evaluations::Dict{<:AbstractSpecies, <:Evaluation},
    observations::Vector{<:Observation}
)
    reports = [
        create_reports(reporter, gen, species_evaluations, observations) 
        for reporter in reporters
    ]

    reports = vcat(reports...)

    return reports
end

function archive_reports!(eco_creator::BasicEcosystemCreator, reports::Vector{<:Report})
    #[archive_report!(eco_creator.archiver, report) for report in reports]

    return nothing
end

function construct_new_species(
    eco_creator::BasicEcosystemCreator, 
    species_evaluations::Dict{<:AbstractSpecies, <:Evaluation}
)
    all_new_species = Dict(
        species.id => create_species(
            eco_creator.species_creators[species.id],
            eco_creator.rng, 
            eco_creator.indiv_id_counter,
            eco_creator.gene_id_counter,
            species,
            evaluation
        ) for (species, evaluation) in species_evaluations
    )

    return all_new_species
end


function create_ecosystem(
    gen::Int, 
    eco_creator::BasicEcosystemCreator,
    eco::Ecosystem, 
    results::Vector{Result}, 
    reports::Vector{Report}
)
    observations = [result.observation for result in results]
    species_evaluations = evaluate_species(eco_creator, eco, results)
    generation_reports = create_all_reports(
        gen, eco_creator.reporters, observations, species_evaluations
    )
    append!(reports, generation_reports)
    archive_reports!(eco_creator.archiver, reports)
    all_new_species = construct_new_species(eco_creator, species_evaluations)
    new_eco = BasicEcosystem(eco_creator.id, all_new_species)
    
    return new_eco
end

function evolve!(
    eco_creator::BasicEcosystemCreator;
    n_gen::Int = 100,
)
    eco = create_ecosystem(eco_creator)
    last_reproduce_time = 0.0
    for gen in 1:n_gen
        eval_time_start = time()
        jobs = create_jobs(eco_creator.job_creator, eco)
        results = perform(eco_creator.job_creator.job_performer, jobs)
        eval_time = time() - eval_time_start
        runtime_report = create_runtime_report(
            eco_creator.runtime_reporter, gen, eval_time, last_reproduce_time
        )
        reports = Report[runtime_report]

        last_reproduce_time_start = time()
        eco = create_ecosystem(eco_creator, gen, eco, results, reports)
        last_reproduce_time = time() - last_reproduce_time_start
    end

    return eco
end

end