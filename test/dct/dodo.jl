using CoEvo.Concrete.Configurations.DensityClassification
using CoEvo.Concrete.States.Basic
using CoEvo.Interfaces

MAX_CLUSTERS = 5
MAX_MUTATIONS = 10


learner_reproducer_config = ReproducerConfiguration(
    id = "R",
    species_type = "new_dodo",
    n_parents = 25,
    n_children = 25,
    selection_type = "identity",
    recombiner = "clone",
    n_explorers = 0,
    max_retirees = 0,
    max_retiree_samples = 0,
    n_dimensions = 128,
    flip_chance = 0.01,
)


learner_evaluator_config = EvaluatorConfiguration(
    id = "R",
    evaluator_type = "new_dodo",
    objective = "performance",
    max_clusters = MAX_CLUSTERS,
)

test_reproducer_config = ReproducerConfiguration(
    id = "IC",
    species_type = "new_dodo",
    n_parents = 25,
    n_children = 25,
    n_explorers = 0,
    max_retirees = 0,
    max_retiree_samples = 0,
    selection_type = "identity",
    recombiner = "clone",
    n_dimensions = 149,
    flip_chance = 0.01
)

test_evaluator_config = EvaluatorConfiguration(
    id = "IC",
    evaluator_type = "new_dodo",
    objective = "distinction",
    max_clusters = MAX_CLUSTERS,
)

config = DensityClassificationExperimentConfiguration(
    id = 1,
    learner_reproducer_config = learner_reproducer_config,
    distinguisher_reproducer_config = test_reproducer_config,
    learner_evaluator_config = learner_evaluator_config,
    distinguisher_evaluator_config = test_evaluator_config,
    seed = abs(rand(Int)),
    n_generations = 50000,
    n_workers = 8,
)

state = BasicEvolutionaryState(config)
evolve!(state)
println("done")

#rule =[1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0]
