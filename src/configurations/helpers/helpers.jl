export make_random_number_generator

function make_random_number_generator(configuration::Configuration)
    seed = configuration.seed
    random_number_generator = configuration.random_number_generator
    if random_number_generator === nothing
        random_number_generator = StableRNG(seed)
    end
    return random_number_generator
end
