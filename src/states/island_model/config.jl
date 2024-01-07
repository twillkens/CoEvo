
Base.@kwdef struct PredictionGameConfiguration
    trial::Int = 1
    n_generations::Int = 100
    seed::Int = 72
    n_ecosystems::Int = 1
    n_workers_per_ecosystem::Int = 1
    # MIGRATION
    migration_interval::Int = 0
    n_migrate::Int = 10
    migration_directions::String = "nsew"
    # GAME
    game::String = "continuous_prediction_game"
    episode_length::Int = 32
    # TOPOLOGY
    topology::String = "two_competitive"
    # SPECIES
    n_population::Int = 100
    n_parents::Int = 50
    n_elites::Int = 0
    n_children::Int = 100
    n_archive::Int = 0
    n_archive_matches::Int = 0
    archive_interval::Int = 0
    max_archive_length::Int = 1000
    #SUBSTRATE
    substrate::String = "function_graphs"
    function_set::String = "all"
    mutation_method::String = "shrink_minor"
    n_mutations::Int = 1
    noise_type::String = "high"
    # EVALUATION
    evaluation_method::String = "disco"
    tournament_size::Int = 3
    distance_method::String = "euclidean"
    clusterer::String = "global_kmeans"
    max_clusters::Int = 5
    # MODES
    modes_interval::Int = 100
    # ELITES
end