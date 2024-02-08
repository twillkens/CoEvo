module NumbersGame

export NumbersGameExperimentConfiguration

import ....Interfaces: create_reproducer, create_simulator, create_evaluator, create_archivers
import ....Interfaces: mutate!, archive!, create_phenotype, create_genotypes
using Random: AbstractRNG, randn
using StatsBase: sample
using ....Abstract
using ....Interfaces
using ...Evaluators.ScalarFitness: ScalarFitnessEvaluator
using ...Evaluators.NSGAII: NSGAIIEvaluator
using ...Evaluators.Distinction: DistinctionEvaluator
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


Base.@kwdef mutable struct NumbersGameExperimentConfiguration <: Configuration
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
    mode::String = "archive_discrete"
end

using ....Abstract

Base.@kwdef struct NumbersGameVectorGenotypeCreator{T <: Real} <: GenotypeCreator
    length::Int = 5
    init_range::Tuple{T, T} = (0.0, .1)
end

using ...Genotypes.Vectors: BasicVectorGenotype

function create_genotypes(
    genotype_creator::NumbersGameVectorGenotypeCreator, n_population::Int, state::State   
)
    genotypes = BasicVectorGenotype{Float64}[]
    for _ in 1:n_population
        genes = zeros(Float64, genotype_creator.length)
        init_start = genotype_creator.init_range[1]
        init_end = genotype_creator.init_range[2]
        for i in 1:genotype_creator.length
            genes[i] = rand(state.rng, init_start:0.01:init_end)
        end
        genotype = BasicVectorGenotype(genes)
        push!(genotypes, genotype)
    end

    return genotypes
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
        genotype.genes[index] += rand(state.rng, -0.15:0.01:0.1)
        if genotype.genes[index] < 0.0
            genotype.genes[index] = 0.0
        end
    end
end

Base.@kwdef struct NumbersGamePhenotypeCreator <: PhenotypeCreator 
    use_delta::Bool = true
    delta::Float64 = 0.25
end

function round_to_nearest_delta(vector::Vector{Float64}, delta::Float64)
    return [floor(x/delta) * delta for x in vector]
end

using ...Phenotypes.Vectors: BasicVectorPhenotype

function create_phenotype(
    phenotype_creator::NumbersGamePhenotypeCreator, id::Int, genotype::BasicVectorGenotype{T}, 
) where T
    #println("in_mutate_values_before = ", genotype.genes)
    if phenotype_creator.use_delta
        values = round_to_nearest_delta(genotype.genes, phenotype_creator.delta)
    else
        values = copy(genotype.genes)
    end
    #println("in_mutate_values_after = ", values)
    return BasicVectorPhenotype(id, values)
end

struct NumbersGameArchiver <: Archiver end

using Serialization

function calculate_average_minimum_gene(individuals::Vector{<:Individual})
    total_minimum_gene = 0.0
    for individual in individuals
        total_minimum_gene += minimum(individual.genotype.genes)
    end
    avg_minimum_gene = length(individuals) > 0 ? total_minimum_gene / length(individuals) : 0.0
    return round(avg_minimum_gene, digits=3)
end

function calculate_num_max_gene_at_index(individuals::Vector{<:Individual}, index::Int)
    num_max_gene = 0
    for individual in individuals
        if argmax(individual.genotype.genes) == index
            num_max_gene += 1
        end
    end
    return num_max_gene
end

function calculate_average_gene_value_at_index(individuals::Vector{<:Individual}, index::Int)
    total_gene_value = 0.0
    for individual in individuals
        total_gene_value += individual.genotype.genes[index]
    end
    avg_gene_value = length(individuals) > 0 ? total_gene_value / length(individuals) : 0.0
    return round(avg_gene_value, digits=3)
end

using DataFrames
using CSV
using DataFrames
using CSV

function collect_species_data(species, generation)
    data_row = DataFrame()
    data_row[!, :generation] = [generation]
    data_row[!, :species_id] = [species.id]

    println("------------")
    println("Generation $generation, Species ID $(species.id)")
    println("Archive Length: ", length(species.archive))

    for i in 1:10
        max_index = calculate_num_max_gene_at_index(species.population, i)
        avg_value = calculate_average_gene_value_at_index(species.population, i)
        data_row[!, Symbol("maxindex_$i")] = [max_index]
        data_row[!, Symbol("avgvalue_$i")] = [avg_value]

        println("Max Index $i: $max_index, Avg Value $i: $avg_value")
    end
    if species.id == "B"
        for i in 1:10
            max_index = calculate_num_max_gene_at_index(species.archive, i)
            avg_value = calculate_average_gene_value_at_index(species.archive, i)
            #data_row[!, Symbol("maxindex_$i")] = [max_index]
            #data_row[!, Symbol("avgvalue_$i")] = [avg_value]

            println("ARCHIVE Max Index $i: $max_index, Avg Value $i: $avg_value")
        end
    end

    avg_min_gene = calculate_average_minimum_gene(species.population)
    data_row[!, :avgmin_gene] = [avg_min_gene]

    println("Average Minimum Gene: $avg_min_gene")
    println("------------")

    return data_row
end

function append_to_csv(df, csv_path)
    if isfile(csv_path)
        existing_df = CSV.read(csv_path, DataFrame)
        append!(existing_df, df)
        CSV.write(csv_path, existing_df)
    else
        CSV.write(csv_path, df)
    end
end

function archive!(::NumbersGameArchiver, state::State)
    all_data = DataFrame()
    for species in state.ecosystem.all_species
        species_data = collect_species_data(species, state.generation)
        append!(all_data, species_data)
    end
    #mode = state.configuration.mode
    #csv_dir = "trials/$mode"
    #if !isdir(csv_dir)
    #    mkpath(csv_dir)
    #end
    #csv_path = "$csv_dir/$(state.id).csv"
    #append_to_csv(all_data, csv_path)
end


function create_archivers(::NumbersGameExperimentConfiguration)
    archivers = [NumbersGameArchiver()]
    return archivers
end

#function create_reproducer(config::NumbersGameExperimentConfiguration)
#    selector = config.evaluator_type == "roulette" ? 
#        FitnessProportionateSelector(n_parents = 100) : 
#        TournamentSelector(n_parents = 100, tournament_size = 5)
#    use_delta = config.mode in ["archive_discrete", "noarchive_discrete"]
#    reproducer = BasicReproducer(
#        species_ids = ["A", "B"],
#        gene_id_counter = BasicCounter(),
#        genotype_creator = NumbersGameVectorGenotypeCreator(length = 3),
#        recombiner = CloneRecombiner(),
#        mutator = NumbersGameVectorMutator(),
#        phenotype_creator = NumbersGamePhenotypeCreator(use_delta = use_delta),
#        individual_id_counter = BasicCounter(),
#        individual_creator = BasicIndividualCreator(),
#        selector = selector,
#        species_creator = ArchiveSpeciesCreator(
#            n_population = 200,
#            n_parents = 100,
#            n_children = 100,
#            n_elites = 100,
#            n_archive = 25,
#            archive_interval = 1,
#            max_archive_length = 10000,
#            max_archive_matches = 0,
#        ),
#        ecosystem_creator = SimpleEcosystemCreator(),
#    )
#    return reproducer
#end
function create_reproducer(config::NumbersGameExperimentConfiguration)
    selector = config.evaluator_type == "roulette" ? 
        FitnessProportionateSelector(n_parents = 100) : 
        TournamentSelector(n_parents = 50, tournament_size = 3)
    use_delta = config.mode in ["archive_discrete", "noarchive_discrete"]
    reproducer = BasicReproducer(
        species_ids = ["A", "B"],
        gene_id_counter = BasicCounter(),
        genotype_creator = NumbersGameVectorGenotypeCreator(length = 10),
        recombiner = CloneRecombiner(),
        mutator = NumbersGameVectorMutator(),
        phenotype_creator = NumbersGamePhenotypeCreator(use_delta = use_delta),
        individual_id_counter = BasicCounter(),
        individual_creator = BasicIndividualCreator(),
        selector = selector,
        species_creator = ArchiveSpeciesCreator(
            n_population = 100,
            n_parents = 50,
            n_children = 50,
            n_elites = 50,
            n_archive = 25,
            archive_interval = 1,
            max_archive_length = 1000,
            max_archive_matches = 0,
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
            include_distinctions = false,
            max_clusters = 10,
            scalar_fitness_evaluator = ScalarFitnessEvaluator(),
            clusterer = config.clusterer_type,
            distance_method = config.distance_method
        )
    elseif config.evaluator_type == "distinction"
        return DistinctionEvaluator(
            maximize = true, 
            max_clusters = 10,
            clusterer = config.clusterer_type,
            distance_method = config.distance_method
        )
    else

        error("Invalid evaluation method: $(config.evaluator_type)")
    end
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