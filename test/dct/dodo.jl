using CoEvo.Concrete.Configurations.DensityClassification
using CoEvo.Concrete.States.Basic
using CoEvo.Interfaces

MAX_CLUSTERS = 10
MAX_MUTATIONS = 10


learner_reproducer_config = ReproducerConfiguration(
    id = "R",
    species_type = "basic",
    n_population = 100,
    n_elites = 50,
    n_parents = 50,
    n_children = 50,
    selection_type = "tournament",
    tournament_size = 3,
    recombiner = "n_point_crossover",
    n_dimensions = 128,
    flip_chance = 0.05,
)


learner_evaluator_config = EvaluatorConfiguration(
    id = "R",
    evaluator_type = "disco",
    objective = "performance",
    clusterer_type = "global_kmeans",
    distance_method = "euclidean",
    max_clusters = MAX_CLUSTERS,
)

distinguisher_reproducer_config = ReproducerConfiguration(
    id = "IC",
    species_type = "dodo",
    n_population = 100,
    max_archive_size = 100,
    max_mutations = 100,
    recombiner = "clone",
    n_dimensions = 149,
    flip_chance = 0.05
)

distinguisher_evaluator_config = EvaluatorConfiguration(
    id = "IC",
    evaluator_type = "dodo",
    objective = "distinctions",
    max_clusters = MAX_CLUSTERS,
)

config = DensityClassificationExperimentConfiguration(
    id = 1,
    learner_reproducer_config = learner_reproducer_config,
    distinguisher_reproducer_config = distinguisher_reproducer_config,
    learner_evaluator_config = learner_evaluator_config,
    distinguisher_evaluator_config = distinguisher_evaluator_config,
    seed = abs(rand(Int)),
    n_generations = 500,
    n_workers = 8,
)

state = BasicEvolutionaryState(config)
evolve!(state)
println("done")