using Distributed

# Add as many worker processes as you'd like (e.g., the number of trials you plan to run)
n_trials = 5 # for example, adjust to the number of desired parallel trials
addprocs(n_trials) # `n` should be the number of trials you want to run in parallel

@everywhere begin
    using CoEvo
    using .Configurations.Concrete: PredictionGameTrialConfiguration
    using StableRNGs: StableRNG
end

seeds = [rand(UInt32) for _ in 1:n_trials]
println("seeds: $seeds")

@distributed for trial in 1:n_trials
    seed = seeds[trial]
    rng = StableRNG(seed)
    configuration = PredictionGameTrialConfiguration(
        trial = trial,
        n_population = 50,
        random_number_generator = rng,
        report_type = :deploy,
        cohorts = [:population, :children],
        n_truncate = 50,
        n_workers = 5,
        episode_length = 16
    )
    
    evolve!(configuration, n_generations=5000)
end
