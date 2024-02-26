using CoEvo.Concrete.Configurations.DensityClassification
using CoEvo.Concrete.States.Basic
using CoEvo.Interfaces

MAX_CLUSTERS = 5
MAX_MUTATIONS = 10


learner_reproducer_config = ReproducerConfiguration(
    id = "R",
    species_type = "dodo_learner",
    n_parents = 50,
    selection_type = "uniform_random",
    recombiner = "n_point_crossover",
    n_dimensions = 128,
    flip_chance = 0.01,
)


learner_evaluator_config = EvaluatorConfiguration(
    id = "R",
    evaluator_type = "dodo_learner",
    max_clusters = MAX_CLUSTERS,
)

test_reproducer_config = ReproducerConfiguration(
    id = "IC",
    species_type = "dodo_test",
    n_population = 50,
    max_archive_size = 1000,
    recombiner = "clone",
    n_dimensions = 149,
    flip_chance = 0.01
)

test_evaluator_config = EvaluatorConfiguration(
    id = "IC",
    evaluator_type = "dodo_test",
    max_clusters = MAX_CLUSTERS,
)

config = DensityClassificationExperimentConfiguration(
    id = 1,
    learner_reproducer_config = learner_reproducer_config,
    distinguisher_reproducer_config = test_reproducer_config,
    learner_evaluator_config = learner_evaluator_config,
    distinguisher_evaluator_config = test_evaluator_config,
    seed = abs(rand(Int)),
    n_generations = 500,
    n_workers = 8,
)

state = BasicEvolutionaryState(config)
evolve!(state)
println("done")
