module NumbersGame

export NumbersGameExperimentConfiguration

import ....Evaluators: evaluate
using ....Evaluators: Evaluator, Evaluation
using ....Species: AbstractSpecies
using ....Evaluators.ScalarFitness: ScalarFitnessEvaluator
using ....Evaluators.NSGAII: NSGAIIEvaluator
using ...ExperimentConfigurations: ExperimentConfiguration
using ....Selectors.Tournament: TournamentSelector
using ....Selectors.FitnessProportionate: FitnessProportionateSelector
using ....NewConfigurations.GlobalConfigurations.Basic: BasicGlobalConfiguration
using ....SpeciesCreators.Basic: BasicSpeciesCreator
using ....Genotypes.Vectors: BasicVectorGenotypeCreator, BasicVectorGenotype
using ....Individuals.Basic: BasicIndividualCreator
using ....Phenotypes.Defaults: DefaultPhenotypeCreator
using ....Replacers.Truncation: TruncationReplacer
using ....Recombiners.Clone: CloneRecombiner
using ....Mutators: Mutator
import ....Mutators: mutate
using ....Counters: Counter
using Random: AbstractRNG, randn
using StatsBase: sample
using ....Abstract.States: get_generation

struct NumbersGameExperimentConfiguration <: ExperimentConfiguration
    id::String
    globals::BasicGlobalConfiguration
    evaluation::String
    game::String
    clusterer::String
    distance_method::String
end

function NumbersGameExperimentConfiguration(;
    trial::Int = 1, 
    seed::Int = 42, 
    evaluation::String = "disco", 
    game::String = "COA",
    clusterer::String = "xmeans",
    distance_method::String = "euclidean",
    kwargs...
)
    id = "ng_trial_$trial"
    globals = BasicGlobalConfiguration(id = id, n_trials=1, trial = trial, seed = seed, n_generations = 500, n_workers = 1)
    return NumbersGameExperimentConfiguration(id, globals, evaluation, game, clusterer, distance_method)
end

function make_evaluator(evaluation::String, clusterer::String, distance_method::String)
    if evaluation == "roulette"
        return ScalarFitnessEvaluator()
    elseif evaluation == "disco"
        return NSGAIIEvaluator(
            maximize = true, 
            perform_disco = true, 
            max_clusters = 5,
            scalar_fitness_evaluator = ScalarFitnessEvaluator(),
            clusterer = clusterer,
            distance_method = distance_method
        )
    else
        error("Invalid evaluation method: $evaluation")
    end
end

function make_selector(evaluation::String)
    if evaluation == "roulette"
        return FitnessProportionateSelector(n_parents = 100)
    elseif evaluation == "disco"
        return TournamentSelector(n_parents = 100, tournament_size = 5)
    else
        error("Invalid evaluation method: $evaluation")
    end
end

struct DistinctionEvaluator <: Evaluator end

struct DistinctionRecord
    id::Int
    fitness::Int
end

struct DistinctionEvaluation <: Evaluation
    id::String
    records::Vector{DistinctionRecord}
end

using ....Species: get_individuals_to_evaluate

function evaluate(
    ::DistinctionEvaluator,
    ::AbstractRNG,
    species::AbstractSpecies,
    outcomes::Dict{Int, Dict{Int, Float64}}
)
    records = DistinctionRecord[]
    ids = [individual.id for individual in get_individuals_to_evaluate(species)]
    outcomes = filter(outcome -> outcome[1] in ids, outcomes)

    for (individual_id, opponent_outcomes) in outcomes
        fitness = 1
        opponents = keys(opponent_outcomes)

        # Iterate through each pair of opponents
        for opponent_A in opponents
            for opponent_B in opponents
                # Skip if comparing the same opponent
                if opponent_A == opponent_B
                    continue
                end
                # Increase fitness if the outcome against opponent_A is different from opponent_B
                if opponent_outcomes[opponent_A] != opponent_outcomes[opponent_B]
                    fitness += 1
                end
            end
        end

        # Store the evaluation record for this individual
        push!(records, DistinctionRecord(individual_id, fitness))
    end

    # Create and return the DistinctionEvaluation
    return DistinctionEvaluation(species.id, records)
end




Base.@kwdef struct NumbersGameVectorMutator <: Mutator
    noise_standard_deviation::Float64 = 0.1
end

function mutate(
    mutator::NumbersGameVectorMutator, 
    rng::AbstractRNG,
    ::Counter,
    genotype::BasicVectorGenotype{T}
) where T
    #noise_vector = randn(rng, T, length(genotype))
    new_genes = deepcopy(genotype.genes)
    noise_vector = rand(rng, -0.1:0.0001:0.1, length(genotype))
    indices_to_mutate = sample(1:length(genotype.genes), 2; replace = false)
    for index in indices_to_mutate
        new_genes[index] = new_genes[index] + noise_vector[index] #* mutator.noise_standard_deviation
    end
    mutated_genotype = BasicVectorGenotype(new_genes)
    return mutated_genotype
end

function make_species_creators(config::NumbersGameExperimentConfiguration)
    species_creator_A = 
        BasicSpeciesCreator(
            id = "A",
            n_population = 100,
            n_children = 100,
            genotype_creator = BasicVectorGenotypeCreator([0.0, 0.0, 0.0, 0.0, 0.0]),
            individual_creator = BasicIndividualCreator(),
            phenotype_creator = DefaultPhenotypeCreator(),
            evaluator = make_evaluator(config.evaluation, config.clusterer, config.distance_method),
            replacer = TruncationReplacer(100),
            selector = make_selector(config.evaluation),
            recombiner = CloneRecombiner(),
            mutators = [NumbersGameVectorMutator()]
        ) 
    species_creator_B = 
        BasicSpeciesCreator(
            id = "B",
            n_population = 100,
            n_children = 100,
            genotype_creator = BasicVectorGenotypeCreator([0.0, 0.0, 0.0, 0.0, 0.0]),
            individual_creator = BasicIndividualCreator(),
            phenotype_creator = DefaultPhenotypeCreator(),
            evaluator = make_evaluator(config.evaluation, config.clusterer, config.distance_method),
            replacer = TruncationReplacer(100),
            selector = make_selector(config.evaluation),
            recombiner = CloneRecombiner(),
            mutators = [NumbersGameVectorMutator()]
        ) 
        #BasicSpeciesCreator(
        #    id = "B",
        #    n_population = 100,
        #    n_children = 100,
        #    genotype_creator = BasicVectorGenotypeCreator([0.0, 0.0, 0.0, 0.0, 0.0]),
        #    individual_creator = BasicIndividualCreator(),
        #    phenotype_creator = DefaultPhenotypeCreator(),
        #    evaluator = DistinctionEvaluator(),
        #    replacer = TruncationReplacer(100),
        #    selector = FitnessProportionateSelector(n_parents = 100),
        #    recombiner = CloneRecombiner(),
        #    mutators = [NumbersGameVectorMutator()]
        #)
    return [species_creator_A, species_creator_B]
end

using ....Ecosystems.Simple: SimpleEcosystemCreator
import ...NewConfigurations.ExperimentConfigurations: make_ecosystem_creator, make_archivers, make_job_creator, make_performer

function make_ecosystem_creator(config::NumbersGameExperimentConfiguration)
    ecosystem_creator = SimpleEcosystemCreator(
        id = config.id,
        species_creators = make_species_creators(config)
    )
    return ecosystem_creator
end


import ....Archivers: Archiver, archive!
using ....Abstract.States: State
using ....Species: get_population

struct NumbersGameArchiver <: Archiver end

function archive!(::NumbersGameArchiver, state::State)
    species = first(state.ecosystem.species)
    s_A = 0.0
    for individual in get_population(species)
        s_A += sum(individual.genotype.genes)
    end
    species = state.ecosystem.species[2]
    s_B = 0.0
    for individual in get_population(species)
        s_B += sum(individual.genotype.genes)
    end
    generation = get_generation(state)
    println("$generation: s_A = $s_A, s_B = $s_B")
end
    
    

function make_archivers(::NumbersGameExperimentConfiguration)
    return [NumbersGameArchiver()]
end

using ....Jobs.Basic: BasicJobCreator
using ....Performers.Basic: BasicPerformer
using ....Interactions.Basic: BasicInteraction
using ....Environments.Stateless: StatelessEnvironmentCreator
using ....Domains.NumbersGame: NumbersGameDomain
using ....MatchMakers.AllVersusAll: AllVersusAllMatchMaker

make_job_creator(config::NumbersGameExperimentConfiguration) = BasicJobCreator(
    n_workers = 1,
    interactions = [
        BasicInteraction(
            id = "numbers_game",
            environment_creator = StatelessEnvironmentCreator(
                domain = NumbersGameDomain(config.game)
            ),
            species_ids = ["A", "B"],
            matchmaker = AllVersusAllMatchMaker(),
        )
    ]
)

make_performer(::NumbersGameExperimentConfiguration) = BasicPerformer(n_workers = 1)

end