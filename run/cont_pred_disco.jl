using Distributed

println("Welcome to CoEvo!")
println("What is the name of the experiment?")
eco_id = readline()
trials_dir_path = "trials/$eco_id"
while isdir(trials_dir_path)
    println("The experiment already exists. Would you like to overwrite it? (y/n)")
    overwrite = readline()
    if overwrite == "n"
        println("Please enter a new name for the experiment:")
        global eco_id = readline()
        global trials_dir_path = "trials/$eco_id"
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
if n_workers == 1
    evolve_trial(1, eco_id, n_generations)
else
    pmap(trial -> evolve_trial(trial, eco_id, n_generations), 2:n_workers)
end

println("All trials completed!")