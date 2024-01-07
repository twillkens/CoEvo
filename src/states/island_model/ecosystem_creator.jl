
function get_tournament_size(config::PredictionGameConfiguration)
    if config.tournament_size == 0
        return config.n_population <= 100 ? 3 : 5
    else
        return config.tournament_size
    end
end

make_evaluator(config::PredictionGameConfiguration) = 
    config.evaluation_method == "roulette" ? ScalarFitnessEvaluator() :
    config.evaluation_method == "disco" ? NSGAIIEvaluator(
        maximize = true,
        max_clusters = config.max_clusters,
        clusterer = config.clusterer,
        distance_method = config.distance_method
    ) :
    throw(ArgumentError("Invalid evaluation method: $(config.evaluation_method)"))

make_selector(config::PredictionGameConfiguration) = 
    config.evaluation_method == "roulette" ? FitnessProportionateSelector(n_parents = config.n_children) :
    config.evaluation_method == "disco" ? TournamentSelector(
        n_parents = config.n_children,
        tournament_size = get_tournament_size(config)
    ) :
    throw(ArgumentError("Invalid evaluation method: $(config.evaluation_method)"))

function make_mutator(config::PredictionGameConfiguration)
    function_set = FUNCTION_SETS[config.function_set]
    function_probabilities = Dict(
        Symbol(func) => 1 / length(function_set) for func in function_set
    )
    mutator = FunctionGraphMutator(
        n_mutations = config.n_mutations,
        validate_genotypes = false,
        mutation_probabilities = MUTATION_PROBABILITIES[config.mutation_method],
        noise_std = GAUSSIAN_NOISE_STD[config.noise_type],
        function_probabilities = function_probabilities
    )
    return mutator
end

function make_species_creators(config::PredictionGameConfiguration)
    topology_config = PREDICTION_GAME_TOPOLOGIES[config.topology]
    species_creators = [
        ArchiveSpeciesCreator(
            id = species_id,
            n_population = config.n_population,
            n_parents = config.n_parents,
            n_children = config.n_children,
            n_elites = config.n_elites,
            n_archive = config.n_archive,
            archive_interval = config.archive_interval,
            max_archive_length = config.max_archive_length,
            genotype_creator = FunctionGraphGenotypeCreator(
                n_inputs = 2, n_outputs = 1, n_bias = 1, n_nodes_per_output = 1
            ),
            individual_creator = ModesIndividualCreator(),
            phenotype_creator = EfficientFunctionGraphPhenotypeCreator(),
            evaluator = make_evaluator(config),
            selector = make_selector(config),
            recombiner = CloneRecombiner(),
            mutator = make_mutator(config)
        ) 
        for species_id in topology_config.species_ids
    ]
    return species_creators
end

function make_ecosystem_creator(config::PredictionGameConfiguration, id::Int)
    ecosystem_creator = SimpleEcosystemCreator(
        id = id, species_creators = make_species_creators(config)
    )
    return ecosystem_creator
end