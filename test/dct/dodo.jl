using CoEvo.Concrete.Configurations.DensityClassification
using CoEvo.Concrete.States.Basic
using CoEvo.Interfaces

MAX_CLUSTERS = 10
MAX_MUTATIONS = 10


learner_reproducer_config = ReproducerConfiguration(
    id = "R",
    species_type = "dodo_learner",
    n_parents = 25,
    n_children = 25,
    selection_type = "tournament",
    recombiner = "n_point_crossover",
    n_dimensions = 128,
    flip_chance = 0.02,
)


learner_evaluator_config = EvaluatorConfiguration(
    id = "R",
    evaluator_type = "dodo_learner",
    max_clusters = MAX_CLUSTERS,
)

test_reproducer_config = ReproducerConfiguration(
    id = "IC",
    species_type = "spread_dodo",
    n_population = 50,
    max_archive_size = 1000,
    recombiner = "n_point_crossover",
    n_dimensions = 149,
    flip_chance = 0.02
)

test_evaluator_config = EvaluatorConfiguration(
    id = "IC",
    evaluator_type = "spread_dodo",
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

#rule =[1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0]
