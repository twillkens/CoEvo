module NumbersGame

export NumbersGameConfiguration

import ..Configurations: make_reporters, make_species_creators
import ..Configurations: make_interactions, make_archive_path, make_ecosystem_id

using Distributed
using Base: @kwdef
using Random: AbstractRNG
using StableRNGs: StableRNG
using ...Genotypes.Vectors: BasicVectorGenotypeCreator
using ...Individuals.Basic: BasicIndividualCreator
using ...Phenotypes.Defaults: DefaultPhenotypeCreator
using ...Mutators.Vectors: BasicVectorMutator
using ...SpeciesCreators.Basic: BasicSpeciesCreator
using ...Domains.NumbersGame: NumbersGameDomain
using ...Metrics.Common: AllSpeciesIdentity
using ...Environments.Stateless: StatelessEnvironmentCreator
using ...MatchMakers.AllvsAll: AllvsAllMatchMaker
using ...Interactions.Basic: BasicInteraction
using ...Jobs.Basic: BasicJobCreator
using ...Reporters: Reporter
using ...Reporters.Basic: BasicReporter
using ...Reporters.Runtime: RuntimeReporter
using ...Metrics.Genotypes: GenotypeSum
using ...Metrics.Evaluations: AllSpeciesFitness
using ...Archivers.Basic: BasicArchiver
using ...States.Basic: BasicCoevolutionaryStateCreator
using ...Ecosystems.Basic: BasicEcosystemCreator
using ..Configurations: Configuration
using ..Configurations: make_recombiner, make_replacer, make_matchmaker, make_performer
using ..Configurations: make_selector, make_evaluator, make_job_creator, make_state_creator
using ..Configurations: make_archiver

@kwdef mutable struct NumbersGameConfiguration <: Configuration
    trial::Int = 1
    seed::Int = 777
    reproduction_method::Symbol = :disco
    outcome_metric::Symbol = :Control
    random_number_generator::Union{AbstractRNG, Nothing} = nothing
    noise_standard_deviation::Float64 = 0.1
    individual_id_counter_state::Int = 1
    gene_id_counter_state::Int = 1
    n_workers::Int = 1
    n_population::Int = 50
    n_children::Int = n_population
    n_truncate::Int = n_population
    tournament_size::Int = 3
    max_clusters::Int = 5
    cohorts::Vector{Symbol} = [:population, :children]
    report_type::Symbol = :silent_test
    performer::Symbol = :cache
    replacer::Symbol = :truncation
    recombiner::Symbol = :clone
    matchmaker::Symbol = :all_vs_all
    state_creator::Symbol = :basic_coevolutionary
end

function make_ecosystem_id(configuration::NumbersGameConfiguration)
    reproduction_method = configuration.reproduction_method
    outcome_metric = configuration.outcome_metric
    n_population = configuration.n_population
    trial = configuration.trial
    id = join([reproduction_method, outcome_metric, n_population, trial], "-")
    return id
end

function make_reporters(configuration::NumbersGameConfiguration)
    reporters = Reporter[]
    report_type = configuration.report_type
    print_interval = 0
    save_interval = 0
    if report_type == :silent_test
        runtime_reporter = RuntimeReporter(print_interval = 0)
        return runtime_reporter, reporters
    elseif report_type == :verbose_test
        print_interval = 1
        save_interval = 0
    elseif report_type == :deploy
        print_interval = 25
        save_interval = 1
    else
        throw(ArgumentError("Unrecognized report type: $report_type"))
    end
    runtime_reporter = RuntimeReporter(print_interval = print_interval)
    reporters = Reporter[
        BasicReporter(
            metric = GenotypeSum(), 
            save_interval = save_interval, 
            print_interval = print_interval
        ),
        BasicReporter(
            metric = AllSpeciesFitness(), 
            save_interval = save_interval, 
            print_interval = print_interval
        ),
        BasicReporter(
            metric = AllSpeciesIdentity(), 
            save_interval = save_interval, 
            print_interval = 0
        ),
    ]
    return runtime_reporter, reporters
end

function make_species_creators(configuration::NumbersGameConfiguration)
    species_ids = ["A", "B"]
    genotype_creator = BasicVectorGenotypeCreator()
    individual_creator = BasicIndividualCreator()
    phenotype_creator = DefaultPhenotypeCreator()
    mutators = [BasicVectorMutator(
        noise_standard_deviation = configuration.noise_standard_deviation
    )]
    evaluator = make_evaluator(configuration)
    selector = make_selector(configuration)
    replacer = make_replacer(configuration)
    recombiner = make_recombiner(configuration)
    species_creators = [
        BasicSpeciesCreator(
            id = species_id,
            n_population = configuration.n_population,
            n_children = configuration.n_children,
            genotype_creator = genotype_creator,
            individual_creator = individual_creator,
            phenotype_creator = phenotype_creator,
            evaluator = evaluator,
            replacer = replacer,
            selector = selector,
            recombiner = recombiner,
            mutators = mutators,
        ) 
        for species_id in species_ids
    ]
    return species_creators
end

function make_interactions(configuration::NumbersGameConfiguration)
    species_ids = ["A", "B"]
    id = join([species_ids..., configuration.outcome_metric], "-")
    matchmaker = make_matchmaker(configuration)
    domain = NumbersGameDomain(configuration.outcome_metric)
    environment_creator = StatelessEnvironmentCreator(domain)
    interaction = BasicInteraction(
        id = id,
        environment_creator = environment_creator,
        species_ids = species_ids,
        matchmaker = matchmaker
    )
    interactions = [interaction]
    return interactions
end

function make_archive_path(configuration::NumbersGameConfiguration)
    outcome_metric = configuration.outcome_metric
    reproduction_method = configuration.reproduction_method
    trial = configuration.trial
    jld2_path = "trials/numbers_game/$outcome_metric/$reproduction_method/$trial.jld2"
    return jld2_path
end

end