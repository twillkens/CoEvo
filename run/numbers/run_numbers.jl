using Distributed

# Add worker processes for parallel computation
n_workers = 5 # Set this to the number of parallel tasks you want
addprocs(n_workers)
@everywhere begin
    using Pkg
    Pkg.activate(".")
    using CoEvo.Concrete.Configurations.NumbersGame
    using CoEvo.Concrete.States.Basic
    using CoEvo.Interfaces
    # Function to run the evolution process with a given configuration
    function run_evolution(config_id::Int, mode::String)
        config = NumbersGameExperimentConfiguration(
            id = config_id,
            domain = "CompareOnOne", 
            evaluator_type = "distinction", 
            clusterer_type = "global_kmeans", 
            distance_method = "euclidean", 
            seed = abs(rand(Int)),
            archive_type = "basic",
            n_workers = 1,
            n_generations = 250,
            mode = mode
        )
        state = BasicEvolutionaryState(config)
        evolve!(state)
        return "Evolution $config_id done"
    end
end

for mode in ["archive_discrete", "archive_continuous", "noarchive_discrete", "noarchive_continuous"]
    println("Running evolution in mode $mode")
    # Running the simulations in parallel
    results = []
    for i in 1:n_workers
        push!(results, @spawn run_evolution(i, mode))
    end

    # Collecting the results
    for res in results
        println(fetch(res))
    end
end

#
## Running the simulations in parallel
#results = []
#for i in 1:n_workers
#    push!(results, @spawn run_evolution(i))
#end
#
## Collecting the results
#for res in results
#    println(fetch(res))
#end
#