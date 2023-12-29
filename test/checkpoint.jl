
using CoEvo.NewConfigurations.ExperimentConfigurations.PredictionGame
using CoEvo.Abstract.States
using CoEvo.States.Evolutionary
using CoEvo.Archivers
using HDF5
using Test

@testset "Checkpointing" begin

mkpath("test/tmp")
ENV["COEVO_TRIAL_DIR"] = "test/tmp"
original_stdout = stdout
output_file = open("test/normal.out", "w")
redirect_stdout(output_file)
config = PredictionGameExperimentConfiguration(
    n_generations = 50, 
    seed = 777,
    topology = "two_competitive",
    episode_length = 8,
    n_population = 5,
    n_children = 5,
    n_elites = 0,
    mutation = "shrink_volatile",
    noise_std = "high",
    archive_interval = 10,
    reproducer = "disco",
)

state = EvolutionaryState(config)
state = evolve(state)
rng_state_clean = get_rng(state).state
close(output_file)

output_file = open("test/checkpoint.out", "w")
redirect_stdout(output_file)

using CoEvo.States.Evolutionary

function evolve_to_n!(state::EvolutionaryState, n::Int)
    while get_generation(state) < n
        state = create_state(state)
        archive!(state)
        #if get_generation(state) == 50
        #    return state
        #end
    end
    return state
end
function evolve_to_n!(config::PredictionGameExperimentConfiguration, n::Int)
    archive_path = get_archive_path(config)
    if !isfile(archive_path)
        println("Creating new archive at $archive_path")
        mkpath(get_root_directory(config))
        file = h5open(archive_path, "w")
        archive!(file, config, "configuration")
        close(file)
        state = EvolutionaryState(config)
    else 
        println("Loading archive from $archive_path")
        file = h5open(archive_path, "r+")
        state = load_state_from_checkpoint(file)
        close(file)
    end
    state = evolve_to_n!(state, n)
    return state
end

evolve_to_n!(config, 20)
state = evolve!(config)
rng_state_after_checkpoint = get_rng(state).state
#println("rng_state_after: $rng_state_after")
rm("test/tmp", recursive = true, force = true)
close(output_file)

mkpath("test/tmp")
output_file = open("test/corrupt.out", "w")
redirect_stdout(output_file)
evolve_to_n!(config, 20)
file = h5open(get_archive_path(config), "r+")
HDF5.delete_object(file, "generations/20/valid")
state = evolve!(config)
rng_state_after_corruption = get_rng(state).state

rm("test/tmp", recursive = true, force = true)
close(output_file)
redirect_stdout(original_stdout)
@test rng_state_clean == rng_state_after_checkpoint
@test rng_state_clean == rng_state_after_corruption

end