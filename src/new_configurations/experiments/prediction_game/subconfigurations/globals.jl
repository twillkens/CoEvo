using ...NewConfigurations.GlobalConfigurations.Basic: BasicGlobalConfiguration

function get_globals(;
    trial::Int = 1,
    n_generations::Int = 100,
    n_workers::Int = 1,
    seed::Int = 42,
    kwargs...
)
    configuration = BasicGlobalConfiguration(
        trial = trial,
        n_generations = n_generations,
        n_workers = n_workers,
        seed = seed,
    )
    return configuration
end