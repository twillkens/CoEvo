using Distributed
using DataStructures: OrderedDict

println("Welcome to CoEvo!")
println("Please choose an experiment to run:")
experiments = OrderedDict(
    "1" => "ContinuousPredictionGameThreeMixGnarlDisco",
    "2" => "ContinuousPredictionGameThreeMixGnarlRoulette",
    "3" => "ContinuousPredictionGameThreeMixFunctionGraphsDisco",
    "4" => "ContinuousPredictionGameThreeMixFunctionGraphsRoulette",
)
for (key, value) in experiments
    println("$key: $value")
end

eco_id = readline()

while !haskey(experiments, eco_id)
    println("Invalid experiment ID. Please try again.")
    global eco_id = readline()
end

eco_id = experiments[eco_id]
trials_dir_path = "trials/$eco_id"
while isdir(trials_dir_path)
    println("Trials for this experiment already exist. Would you like to overwrite them? (y/n)")
    overwrite = readline()
    if overwrite == "n"
        println("Goodbye!")
        return
    else
        println("Deleting old experiment...")
        rm(trials_dir_path; recursive = true)
    end
end
mkdir(trials_dir_path)
println("How many trials would you like to run in parallel?")
n_trials = parse(Int, readline())
println("How many generations?")
n_generations = parse(Int, readline())

if n_trials > 1
    addprocs(n_trials)
end
@everywhere using CoEvo
@everywhere using CoEvo.Runners: evolve_trial
# Check number of available workers
n_workers = nprocs()
trials = collect(1:n_trials)
seeds = [rand(UInt32) for _ in 1:n_workers]
seed_file_path = joinpath(trials_dir_path, "seeds.txt")
open(seed_file_path, "w") do io
    for seed in seeds
        println(io, seed)
    end
end
if n_workers == 1
    evolve_trial(1, seeds[1], eco_id, n_generations)
else
    futures = [
        remotecall(evolve_trial, worker, trial, seed, eco_id, n_generations) 
        for (worker, trial, seed) in zip(workers(), trials, seeds)
    ]
    [fetch(f) for f in futures]
    #pmap((trial, seed) -> evolve_trial(trial, seed, eco_id, n_generations), enumerate(seeds))
end

println("All trials completed!")