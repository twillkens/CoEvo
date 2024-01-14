export CircleExperimentConfiguration

using ....Abstract

Base.@kwdef struct CircleExperimentConfiguration <: Configuration
    trial::Int = 1
    n_generations::Int = 20_000
    seed::Int = 72
    n_ecosystems::Int = 1
    n_workers_per_ecosystem::Int = 1
    # GAME
    episode_length::Int = 32
    # TOPOLOGY
    topology::String = "two_competitive"
    # SPECIES
    species::String = "small"
    #SUBSTRATE
    mutator::String = "shrink_moderate"
    # EVALUATION
    evaluator::String = "disco"
    # SELECTION
    selector::String = "tournament"
    # MODES
end