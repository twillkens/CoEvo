using CoEvo.Concrete.Configurations.MaxSolve
using CoEvo.Concrete.States.Basic
using CoEvo.Interfaces
using Distributed
using Random

# Number of trials you want to run
const N_TRIALS = 1

# Initialize required number of worker processes
addprocs(N_TRIALS)

@everywhere begin
    using CoEvo.Concrete.Configurations.MaxSolve
    using CoEvo.Concrete.States.Basic
    using CoEvo.Interfaces
    using Random
end

# Define constants for configuration
@everywhere begin
    const N_LEARNER_POP = 100
    const N_LEARNER_CHILDREN = 100
    const N_TEST_POP = 100
    const N_TEST_CHILDREN = 100
    const N_ARCHIVE = 1000
    const N_GENERATIONS = 10000
# Function to run each trial
function run_trial(trial_id)
    seed = abs(rand(Int))
    Random.seed!(seed)

    config = MaxSolveConfiguration(
        id = trial_id,
        tag = trial_id,
        seed = seed,
        n_mutations = 5,
        learner_algorithm = "disco",
        test_algorithm = "qmeu-immigrant",
        domain = "doc-qmeu-immigrant",
        n_learner_population = N_LEARNER_POP, 
        n_learner_children = N_LEARNER_CHILDREN, 
        n_test_population = N_TEST_POP, 
        n_test_children = N_TEST_CHILDREN,
        max_learner_archive_size = N_ARCHIVE,
        n_generations = N_GENERATIONS,
        n_workers = 1,  # Using 1 worker per trial
        task = "fsm"
    )

    state = BasicEvolutionaryState(config)
    evolve!(state)
    println("Trial $trial_id done")
end
end


# Running the trials in parallel
pmap(run_trial, 1:N_TRIALS)
