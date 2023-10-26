module Basic

export BasicEcosystem, BasicEcosystemCreator

import ..Ecosystems: create_ecosystem, evolve!

using DataStructures: SortedDict
using Random: AbstractRNG
using StableRNGs: StableRNG
using ...Counters: Counter, Basic.BasicCounter
using ...Species: AbstractSpecies
using ...Evaluators: Evaluation, Evaluator, create_evaluation
using ...SpeciesCreators: SpeciesCreator, create_species
using ...SpeciesCreators.Basic: BasicSpeciesCreator
using ...Jobs: JobCreator, create_jobs
using ...Performers: Performer
using ...Interactions: Interaction
using ...Results: Result, get_individual_outcomes, get_observations
using ...Observers: Observation
using ...Observers.Null: NullObservation
using ...Reporters.Runtime: RuntimeReporter, create_runtime_report
using ...Reporters: Reporter, Report, create_report
using ...Archivers: Archiver, archive!, archive_reports!
using ...Performers: perform
using ...States.Basic: BasicCoevolutionaryStateCreator, BasicCoevolutionaryState
using ...States: State, StateCreator
using ..Ecosystems: Ecosystem, EcosystemCreator


struct BasicEcosystem{S <: AbstractSpecies} <: Ecosystem
    id::String
    species::Vector{S}
end

function Base.show(io::IO, eco::BasicEcosystem)
    print(io, "Eco(id: ", eco.id, ", species: ", keys(eco.species), ")")
end

Base.@kwdef struct BasicEcosystemCreator{
    S <: SpeciesCreator, 
    J <: JobCreator, 
    P <: Performer,
    C <: StateCreator,
    R <: Reporter,
    A <: Archiver,
} <: EcosystemCreator
    id::String
    trial::Int
    random_number_generator::AbstractRNG
    species_creators::Vector{S}
    job_creator::J
    performer::P
    state_creator::C
    reporters::Vector{R}
    archiver::A
    individual_id_counter::Counter = BasicCounter(0)
    gene_id_counter::Counter = BasicCounter(0)
    runtime_reporter::RuntimeReporter = RuntimeReporter()
    garbage_collection_interval::Int = 50
end

function show(io::IO, c::BasicEcosystemCreator)
    print(io, "BasicEcosystemCreator(id: ", c.id, 
          ", trial: ", c.trial,
          ", random_number_generator: ", typeof(c.random_number_generator), 
          ", species: ", keys(c.species_creators), 
          ", interactions: ", c.job_creator.interactions,")")
end

function create_ecosystem(ecosystem_creator::BasicEcosystemCreator)
    # Determine species IDs and populate species dictionary
    all_species = [
        create_species(
            species_creator,
            ecosystem_creator.random_number_generator, 
            ecosystem_creator.individual_id_counter, 
            ecosystem_creator.gene_id_counter
        ) 
        for species_creator in ecosystem_creator.species_creators
    ]
    eco = BasicEcosystem(ecosystem_creator.id, all_species)

    return eco
end


function evaluate_species(
    evaluators::Vector{<:Evaluator},
    random_number_generator::AbstractRNG,
    species::Vector{<:AbstractSpecies},
    individual_outcomes::Dict{Int, SortedDict{Int, Float64}},
    observations::Vector{<:Observation},
)
    evaluations = [
        create_evaluation(evaluator, random_number_generator, species, individual_outcomes)
        for (evaluator, species) in zip(evaluators, species)
    ]
    
    return evaluations
end

function evaluate_species(
    ecosystem_creator::BasicEcosystemCreator, 
    ecosystem::Ecosystem, 
    individual_outcomes::Dict{Int, SortedDict{Int, Float64}}, 
    observations::Vector{<:Observation}
)
    evaluators = [
        species_creator.evaluator for species_creator in ecosystem_creator.species_creators
    ]
    evaluations = evaluate_species(
        evaluators, ecosystem_creator.random_number_generator, ecosystem.species, individual_outcomes, observations
    )
    return evaluations
end

function create_state(
    ::BasicCoevolutionaryStateCreator,
    ecosystem_creator::BasicEcosystemCreator,
    generation::Int,
    ecosystem::Ecosystem,
    individual_outcomes::Dict{Int, SortedDict{Int, Float64}},
    evaluations::Vector{<:Evaluation},
    observations::Vector{<:Observation},
)
    state = BasicCoevolutionaryState(
        id = ecosystem_creator.id,
        random_number_generator = ecosystem_creator.random_number_generator,
        trial = ecosystem_creator.trial,
        generation = generation,
        individual_id_counter = ecosystem_creator.individual_id_counter,
        gene_id_counter = ecosystem_creator.gene_id_counter,
        species = ecosystem.species,
        individual_outcomes = individual_outcomes,
        evaluations = evaluations,
        observations = observations,
    )
    return state
end

function create_all_reports(state::State, reporters::Vector{<:Reporter})
    reports = [create_report(reporter, state) for reporter in reporters]
    return reports
end

function construct_new_species(
    state::BasicCoevolutionaryState, species_creators::Vector{<:BasicSpeciesCreator}
)
    new_species = [
        create_species(
            species_creators[index],
            state.random_number_generator, 
            state.individual_id_counter,
            state.gene_id_counter,
            state.species[index],
            state.evaluations[index]
        ) for (index) in eachindex(species_creators)
    ]

    return new_species
end

function create_ecosystem(
    ecosystem_creator::BasicEcosystemCreator,
    gen::Int, 
    ecosystem::Ecosystem, 
    results::Vector{<:Result}, 
    reports::Vector{Report}
)
    individual_outcomes = get_individual_outcomes(results)
    observations = get_observations(results)
    evaluations = evaluate_species(
        ecosystem_creator, ecosystem, individual_outcomes, observations
    )
    state = create_state(
        ecosystem_creator.state_creator, 
        ecosystem_creator, 
        gen, 
        ecosystem, 
        individual_outcomes,
        evaluations,
        observations,
    )
    generation_reports = create_all_reports(state, ecosystem_creator.reporters)
    append!(reports, generation_reports)
    archive_reports!(ecosystem_creator.archiver, reports)
    if gen % ecosystem_creator.garbage_collection_interval == 0
        Base.GC.gc()
    end
    all_new_species = construct_new_species(state, ecosystem_creator.species_creators)
    new_eco = BasicEcosystem(ecosystem_creator.id, all_new_species)
    
    return new_eco
end
using JLD2: @save


function evolve!(
    ecosystem_creator::BasicEcosystemCreator;
    n_generations::Int = 100,
)
    ecosystem = create_ecosystem(ecosystem_creator)
    last_reproduce_time = 0.0
    for generation in 1:n_generations
        eval_time_start = time()
        phenotype_creators = [
            species_creator.phenotype_creator 
            for species_creator in ecosystem_creator.species_creators
        ]
        jobs = create_jobs(
            ecosystem_creator.job_creator,
            ecosystem_creator.random_number_generator, 
            ecosystem.species,
            phenotype_creators,
        )
        results = perform(ecosystem_creator.performer, jobs)
        eval_time = time() - eval_time_start
        runtime_report = create_runtime_report(
            ecosystem_creator.runtime_reporter, 
            ecosystem_creator.id, 
            generation, 
            eval_time, 
            last_reproduce_time
        )
        reports = Report[runtime_report]

        last_reproduce_time_start = time()
        ecosystem = create_ecosystem(ecosystem_creator, generation, ecosystem, results, reports)
        last_reproduce_time = time() - last_reproduce_time_start
    end

    return ecosystem
end

end
