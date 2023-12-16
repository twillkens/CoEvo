export make_random_number_generator

function make_random_number_generator(configuration::Configuration)
    seed = configuration.seed
    rng = configuration.rng
    if rng === nothing
        rng = StableRNG(seed)
    end
    return rng
end
