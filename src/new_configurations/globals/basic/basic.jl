module Basic

export BasicGlobalConfiguration
export make_performer
export make_random_number_generator

import ...GlobalConfigurations: make_random_number_generator, make_performer
import ....Abstract.States: get_n_generations, get_n_workers, get_trial, get_seed

using Random: AbstractRNG
using StableRNGs: StableRNG
using ....Counters.Basic: BasicCounter
using ....Performers.Cache: CachePerformer
using ...GlobalConfigurations: GlobalConfiguration

Base.@kwdef struct BasicGlobalConfiguration <: GlobalConfiguration
    id::String = "globals"
    trial::Int
    n_generations::Int
    n_workers::Int
    seed::Int
end

get_n_generations(config::BasicGlobalConfiguration) = config.n_generations
get_n_workers(config::BasicGlobalConfiguration) = config.n_workers
get_trial(config::BasicGlobalConfiguration) = config.trial
get_seed(config::BasicGlobalConfiguration) = config.seed

function make_random_number_generator(configuration::BasicGlobalConfiguration)
    if configuration.seed < 0
        throw(ArgumentError("Seed must be non-negative"))
    end
    rng = StableRNG(configuration.seed)
    return rng
end

make_performer(config::BasicGlobalConfiguration) = CachePerformer(n_workers = config.n_workers)
    
end