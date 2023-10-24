using Distributed
using ClusterManagers

trial_id = parse(Int, ARGS[1])  # Get the trial ID from command line argument
seed = parse(UInt32, ARGS[2])   # Get the seed from command line argument

# Add 5 workers for this trial
addprocs(5)

@everywhere begin
    using CoEvo
    using .Configurations.Concrete: PredictionGameTrialConfiguration
    using StableRNGs: StableRNG
end

random_number_generator = StableRNG(seed)
configuration = PredictionGameTrialConfiguration(
    trial = trial_id,
    n_population = 50,
    random_number_generator = random_number_generator,
    report_type = :deploy,
    cohorts = [:population, :children],
    n_truncate = 50,
    n_workers = 5,
    episode_length = 16
)

evolve!(configuration, n_generations=5000)
