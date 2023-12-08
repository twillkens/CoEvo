using CoEvo
using CoEvo.Names
using CoEvo.Configurations.PredictionGame
using CoEvo.Genotypes.FunctionGraphs
using Test
using Random


experiment = make_prediction_game_experiment(;
    game = "continuous_prediction_game",
    topology = "two_control",
    substrate = "function_graphs",
    reproducer = "disco",
    trial = 1,
    n_population = 50,
    n_children = 50,
    seed = 777,
    report = "deploy",
    cohorts = ["population", "children"],
    communication_dimension = 0,
    n_workers = 1,
    episode_length = 16,
    n_nodes_per_output = 1,
    modes_interval = 50
)

println("Running experiment...")

run!(experiment; n_generations = 10_000)

println("Done!")