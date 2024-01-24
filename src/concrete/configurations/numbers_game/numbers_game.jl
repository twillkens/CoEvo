module NumbersGame

export NumbersGameExperimentConfiguration

import ....Interfaces: create_reproducer, create_simulator, create_evaluator, create_archivers
import ....Interfaces: mutate!, archive!
using Random: AbstractRNG, randn
using StatsBase: sample
using ....Abstract
using ....Interfaces
using ...Evaluators.ScalarFitness: ScalarFitnessEvaluator
using ...Evaluators.NSGAII: NSGAIIEvaluator
using ...Selectors.Tournament: TournamentSelector
using ...Selectors.FitnessProportionate: FitnessProportionateSelector
using ...SpeciesCreators.Archive: ArchiveSpeciesCreator
using ...Genotypes.Vectors: BasicVectorGenotypeCreator, BasicVectorGenotype
using ...Individuals.Basic: BasicIndividualCreator
using ...Phenotypes.Defaults: DefaultPhenotypeCreator
using ...Recombiners.Clone: CloneRecombiner
using ...Counters.Basic: BasicCounter
using ...Ecosystems.Simple: SimpleEcosystemCreator
using ...Simulators.Basic: BasicSimulator
using ...Interactions.Basic: BasicInteraction
using ...Environments.Stateless: StatelessEnvironmentCreator
using ...Domains.NumbersGame: NumbersGameDomain
using ...MatchMakers.AllVersusAll: AllVersusAllMatchMaker
using ...Reproducers.Basic: BasicReproducer
using ...Jobs.Simple: SimpleJobCreator
using ...Performers.Basic: BasicPerformer
using ...Performers.Cache: CachePerformer


Base.@kwdef struct NumbersGameExperimentConfiguration <: Configuration
    id::Int = 1
    evaluator_type::String = "disco"
    domain::String = "COA"
    clusterer_type::String = "global_kmeans"
    distance_method::String = "euclidean"
    archive_type::String = "basic"
    seed::Int = abs(rand(Int))
    checkpoint_interval::Int = 1
    n_generations::Int = 500
    n_workers::Int = 1
end

function create_reproducer(config::NumbersGameExperimentConfiguration)
    reproducer = BasicReproducer(
        species_ids = ["A", "B"],
        gene_id_counter = BasicCounter(),
        genotype_creator = BasicVectorGenotypeCreator([0.0, 0.0, 0.0, 0.0, 0.0]),
        recombiner = CloneRecombiner(),
        mutator = NumbersGameVectorMutator(),
        phenotype_creator = DefaultPhenotypeCreator(),
        individual_id_counter = BasicCounter(),
        individual_creator = BasicIndividualCreator(),
        selector = TournamentSelector(n_parents = 100, tournament_size = 5),
        species_creator = ArchiveSpeciesCreator(
            n_population = 200,
            n_parents = 100,
            n_children = 100,
            n_elites = 100,
            n_archive = config.archive_type == "none" ? 0 : 5,
            archive_interval = 1,
            max_archive_length = config.archive_type == "none" ? 0 : 500,
            max_archive_matches = 100,
        ),
        ecosystem_creator = SimpleEcosystemCreator(),
    )
    return reproducer
end


function create_simulator(config::NumbersGameExperimentConfiguration) 
    simulator = BasicSimulator(
        interactions = [
            BasicInteraction(
                id = "numbers_game",
                environment_creator = StatelessEnvironmentCreator(
                    domain = NumbersGameDomain(config.domain)
                ),
                species_ids = ["A", "B"],
            )
        ],
        matchmaker = AllVersusAllMatchMaker(),
        job_creator = SimpleJobCreator(n_workers = config.n_workers),
        performer = CachePerformer(n_workers = config.n_workers),
    )
    return simulator
end

function create_evaluator(config::NumbersGameExperimentConfiguration)
    if config.evaluator_type == "roulette"
        return ScalarFitnessEvaluator()
    elseif config.evaluator_type == "disco"
        return NSGAIIEvaluator(
            maximize = true, 
            perform_disco = true, 
            max_clusters = 5,
            scalar_fitness_evaluator = ScalarFitnessEvaluator(),
            clusterer = config.clusterer_type,
            distance_method = config.distance_method
        )
    else

        error("Invalid evaluation method: $(config.evaluator_type)")
    end
end

Base.@kwdef struct NumbersGameVectorMutator <: Mutator
    noise_standard_deviation::Float64 = 0.1
end

function mutate!(
    ::NumbersGameVectorMutator, genotype::BasicVectorGenotype{T}, state::State
) where T
    #noise_vector = randn(rng, T, length(genotype))
    indices_to_mutate = sample(1:length(genotype.genes), 2; replace = false)
    for index in indices_to_mutate
        genotype.genes[index] += rand(state.rng, -0.1:0.0001:0.1)
    end
end

struct NumbersGameArchiver <: Archiver end

function archive!(::NumbersGameArchiver, state::State)
    species = first(state.ecosystem.all_species)
    println("A_archive_length = ", length(species.archive))
    s_A = 0.0
    for individual in species.population
        s_A += sum(individual.genotype.genes)
    end
    species = state.ecosystem.all_species[2]
    println("B_archive_length = ", length(species.archive))
    s_B = 0.0
    for individual in species.population
        s_B += sum(individual.genotype.genes)
    end
    generation = state.generation
    println("$generation: s_A = $s_A, s_B = $s_B")
end

function create_archivers(::NumbersGameExperimentConfiguration)
    archivers = [NumbersGameArchiver()]
    return archivers
end

end

#struct DistinctionEvaluator <: Evaluator end
#
#struct DistinctionRecord
#    id::Int
#    fitness::Int
#end
#
#struct DistinctionEvaluation <: Evaluation
#    id::String
#    records::Vector{DistinctionRecord}
#end
#
#
#function evaluate(
#    ::DistinctionEvaluator,
#    ::AbstractRNG,
#    species::AbstractSpecies,
#    outcomes::Dict{Int, Dict{Int, Float64}}
#)
#    records = DistinctionRecord[]
#    ids = [individual.id for individual in get_individuals_to_evaluate(species)]
#    outcomes = filter(outcome -> outcome[1] in ids, outcomes)
#
#    for (individual_id, opponent_outcomes) in outcomes
#        fitness = 1
#        opponents = keys(opponent_outcomes)
#
#        # Iterate through each pair of opponents
#        for opponent_A in opponents
#            for opponent_B in opponents
#                # Skip if comparing the same opponent
#                if opponent_A == opponent_B
#                    continue
#                end
#                # Increase fitness if the outcome against opponent_A is different from opponent_B
#                if opponent_outcomes[opponent_A] != opponent_outcomes[opponent_B]
#                    fitness += 1
#                end
#            end
#        end
#
#        # Store the evaluation record for this individual
#        push!(records, DistinctionRecord(individual_id, fitness))
#    end
#
#    # Create and return the DistinctionEvaluation
#    return DistinctionEvaluation(species.id, records)
#end