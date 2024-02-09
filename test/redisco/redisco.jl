using CoEvo.Concrete.Configurations.NumbersGame
using CoEvo.Concrete.States.Basic
using CoEvo.Interfaces

learner_reproducer_config = ReproducerConfiguration(
    id = "L",
    species_type = "basic",
    n_population = 100,
    n_elites = 50,
    n_parents = 50,
    n_children = 50,
    selection_type = "tournament",
    tournament_size = 3,
    max_archive_size = 100,
    n_dimensions = 5,
    initialization_range = (0.0, 0.1),
    discretize_phenotypes = true,
    discretization_delta = 0.25,
)

learner_evaluator_config = EvaluatorConfiguration(
    id = "L",
    evaluator_type = "disco",
    objective = "performance",
    clusterer_type = "global_kmeans",
    distance_method = "euclidean",
    max_clusters = 5,
)

distinguisher_reproducer_config = ReproducerConfiguration(
    id = "D",
    species_type = "redisco",
    n_population = 100,
    max_archive_size = 100,
    max_mutations = 100,
    n_dimensions = 5,
    initialization_range = (0.0, 0.1),
    discretize_phenotypes = true,
    discretization_delta = 0.25,
)

distinguisher_evaluator_config = EvaluatorConfiguration(
    id = "D",
    evaluator_type = "redisco",
    max_clusters = 5,
)

config = NumbersGameExperimentConfiguration(
    id = 1,
    learner_reproducer_config = learner_reproducer_config,
    distinguisher_reproducer_config = distinguisher_reproducer_config,
    learner_evaluator_config = learner_evaluator_config,
    distinguisher_evaluator_config = distinguisher_evaluator_config,
    domain = "CompareOnOne",
    seed = abs(rand(Int)),
    n_generations = 5000,
    n_workers = 1,
)

state = BasicEvolutionaryState(config)
evolve!(state)
println("done")