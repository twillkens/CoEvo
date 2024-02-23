using CoEvo.Concrete.Configurations.NumbersGame
using CoEvo.Concrete.States.Basic
using CoEvo.Interfaces

N_DIMENSIONS = 5
DISCRETIZE_PHENOTYPES = false
MAX_CLUSTERS = 5
MAX_MUTATIONS = 1


#learner_reproducer_config = ReproducerConfiguration(
#    id = "L",
#    species_type = "basic",
#    n_population = 100,
#    n_elites = 50,
#    n_parents = 50,
#    n_children = 50,
#    selection_type = "tournament",
#    tournament_size = 3,
#    max_archive_size = 100,
#    n_dimensions = N_DIMENSIONS,
#    initialization_range = (0.0, 0.1),
#    discretize_phenotypes = DISCRETIZE_PHENOTYPES,
#    discretization_delta = 0.25,
#)

learner_reproducer_config = ReproducerConfiguration(
    id = "L",
    species_type = "basic",
    n_population = 200,
    n_elites = 100,
    n_parents = 100,
    n_children = 100,
    selection_type = "tournament",
    tournament_size = 5,
    max_archive_size = 100,
    n_dimensions = N_DIMENSIONS,
    initialization_range = (0.0, 0.1),
    discretize_phenotypes = DISCRETIZE_PHENOTYPES,
    discretization_delta = 0.25,
)

learner_evaluator_config = EvaluatorConfiguration(
    id = "L",
    evaluator_type = "disco",
    objective = "performance",
    clusterer_type = "global_kmeans",
    distance_method = "euclidean",
    max_clusters = MAX_CLUSTERS,
)

#distinguisher_reproducer_config = ReproducerConfiguration(
#    id = "D",
#    #species_type = "dodo",
#    species_type = "basic",
#    n_population = 100,
#    max_archive_size = 100,
#    max_mutations = MAX_MUTATIONS,
#    max_archive_age = 10000,
#    n_dimensions = N_DIMENSIONS,
#    initialization_range = (0.0, 0.1),
#    discretize_phenotypes = DISCRETIZE_PHENOTYPES,
#    discretization_delta = 0.25,
#)
distinguisher_reproducer_config = ReproducerConfiguration(
    id = "D",
    #species_type = "dodo",
    species_type = "basic",
    n_population = 200,
    n_elites = 100,
    n_parents = 100,
    n_children = 100,
    selection_type = "uniform_random",
    max_mutations = MAX_MUTATIONS,
    n_dimensions = N_DIMENSIONS,
    initialization_range = (0.0, 0.1),
    discretize_phenotypes = DISCRETIZE_PHENOTYPES,
    discretization_delta = 0.25,
)

distinguisher_evaluator_config = EvaluatorConfiguration(
    id = "D",
    #evaluator_type = "dodo",
    evaluator_type = "scalar_fitness",
    objective = "distinctions",
    max_clusters = MAX_CLUSTERS,
)


config = NumbersGameExperimentConfiguration(
    id = 1,
    learner_reproducer_config = learner_reproducer_config,
    distinguisher_reproducer_config = distinguisher_reproducer_config,
    learner_evaluator_config = learner_evaluator_config,
    distinguisher_evaluator_config = distinguisher_evaluator_config,
    domain = "CompareOnOne",
    seed = abs(rand(Int)),
    n_generations = 50_000,
    n_workers = 1,
)

state = BasicEvolutionaryState(config)
evolve!(state)
println("done")