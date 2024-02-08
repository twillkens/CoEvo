using ....Abstract
using ...Reproducers.Basic: BasicReproducer

Base.@kwdef struct NumbersGameReproducerConfiguration
    id::String = "L"
    n_population::Int = 100
    n_parents::Int = 50
    n_children::Int = 50
    n_elites::Int = 50
    max_archive_size::Int
    objective::String = "outcomes"
    method::String = "disco"
    clusterer_type::String = "global_kmeans"
    distance_method::String = "euclidean"
    max_clusters::Int = 10
    n_dimensions::Int = 5
    initialization_range::Tuple{Float64, Float64} = (0.0, 0.1)
    discretize_phenotypes::Bool = true
    discretization_delta::Float64 = 0.25
    max_mutations::Int = 100
    tournament_size::Int = 3
end

Base.@kwdef mutable struct NumbersGameExperimentConfiguration <: Configuration
    id::Int = 1
    learner_config::NumbersGameReproducerConfiguration = NumbersGameReproducerConfiguration()
    evaluator_config::NumbersGameReproducerConfiguration = NumbersGameReproducerConfiguration()
    domain::String = "CompareOnOne"
    seed::Int = abs(rand(Int))
    n_generations::Int = 5000
    n_workers::Int = 1
end

function make_species_creator(config::NumbersGameReproducerConfiguration)
    if config.method in ["roulette", "disco", "tournament"]
        species_creator = BasicSpeciesCreator(
            n_population = config.n_population,
            n_parents = config.n_parents,
            n_children = config.n_children,
            n_elites = config.n_elites,
        )
    elseif config.method in ["redisco", "redisco_naive"]
        species_creator = DistinguisherSpeciesCreator(
            id = config.id,
            n_population = config.n_population,
            max_archive_size = config.max_archive_size,
            max_mutations = config.max_mutations,
        )
    else
        error("Invalid method: $(config.method)")
    end
    return species_creator
end
function make_evaluator(config::NumbersGameReproducerConfiguration)
    if config.method in ["roulette", "tournament"]
        evaluator = ScalarFitnessEvaluator(
            maximize = true,
            objective = config.objective
        )
    elseif config.method == "disco"
        evaluator = DiscoEvaluator(
            maximize = true, 
            objective = config.objective,
            max_clusters = config.max_clusters,
            clusterer = config.clusterer_type,
            distance_method = config.distance_method
        )
    elseif config.method in ["redisco", "redisco_naive"]
        evaluator = RediscoEvaluator(
            maximize = true, 
            max_clusters = 10,
            clusterer = config.clusterer_type,
            distance_method = config.distance_method
        )
    else
        error("Invalid evaluation method: $(config.method)")
    end
    return evaluator
end

function make_selector(config::NumbersGameReproducerConfiguration)
    if config.method == "roulette"
        selector = FitnessProportionateSelector(n_parents = config.n_parents) 
    elseif config.method in ["disco", "tournament"]
        selector = TournamentSelector(n_select = config.n_select, tournament_size = 3)
    elseif config.method in ["redisco", "redisco_naive"]
        selector = IdentitySelector()
    else
        error("Invalid method: $(config.method)")
    end
    return selector
end

function BasicReproducer(config::NumbersGameReproducerConfiguration)
    reproducer = BasicReproducer(
        id = config.id,
        genotype_creator = NumbersGameVectorGenotypeCreator(
            length = config.n_dimensions, init_range = config.initialization_range
        ),
        phenotype_creator = NumbersGamePhenotypeCreator(
            use_delta = config.discretize_phenotypes, delta = config.discretization_delta
        ),
        individual_creator = BasicIndividualCreator(),
        species_creator = make_species_creator(config),
        selector = make_selector(config),
        recombiner = CloneRecombiner(),
        mutator = NumbersGameVectorMutator(),
    )
end


function create_learner_reproducer(config::NumbersGameExperimentConfiguration)

end

function create_evaluator_reproducer(config::NumbersGameExperimentConfiguration)

end

function create_reproducers(config::NumbersGameExperimentConfiguration)
    selector = config.evaluator_type == "roulette" ? 
        FitnessProportionateSelector(n_parents = 100) : 
        TournamentSelector(n_parents = 50, tournament_size = 3)
    use_delta = config.mode in ["archive_discrete", "noarchive_discrete"]
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