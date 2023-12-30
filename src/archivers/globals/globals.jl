module Globals

export GlobalStateArchiver

import ...Archivers: archive!

using HDF5: h5open
using ...Species: AbstractSpecies, get_population_genotypes, get_minimized_population_genotypes
using ...Archivers: Archiver
using ...Archivers.Utilities: get_aggregate_measurements, add_measurements_to_hdf5
using ...Genotypes: get_size
using ...Abstract.States: State, get_all_species, get_generation, get_rng
using ...Abstract.States: get_individual_id_counter, get_gene_id_counter
using ...Abstract.States: get_reproduction_time, get_simulation_time, get_evaluation_time
using ...Abstract.States: get_rng_state_after_creation, get_trial

struct GlobalStateArchiver <: Archiver
    archive_interval::Int
    archive_directory::String
end

function archive!(archiver::GlobalStateArchiver, state::State)
    generation = get_generation(state)
    do_not_archive = archiver.archive_interval == 0
    is_archive_interval = get_generation(state) == 1 ||
        get_generation(state) % archiver.archive_interval == 0
    if do_not_archive || !is_archive_interval
        return
    end
    mkpath("$(archiver.archive_directory)/generations")
    archive_path = "$(archiver.archive_directory)/generations/$generation.h5"
    file = h5open(archive_path, "w")
    base_path = "global_state"
    file["$base_path/generation"] = generation
    file["$base_path/rng_state"] = string(get_rng(state).state)
    file["$base_path/rng_state_after_creation"] = get_rng_state_after_creation(state)
    file["$base_path/individual_id_counter_state"] = get_individual_id_counter(state).current_value
    file["$base_path/gene_id_counter_state"] = get_gene_id_counter(state).current_value
    file["$base_path/reproduction_time"] = get_reproduction_time(state)
    file["$base_path/simulation_time"] = get_simulation_time(state)
    file["$base_path/evaluation_time"] = get_evaluation_time(state)
    println("------Trial: $(get_trial(state)), Generation: $(get_generation(state))------)")
    println("rng_after_creation: $(get_rng_state_after_creation(state)), rng_after_evaluation: $(get_rng(state).state)")
    println("individual_id: $(get_individual_id_counter(state).current_value), gene_id: $(get_gene_id_counter(state).current_value)")
    reproduction_time = round(get_reproduction_time(state); digits = 3)
    simulation_time = round(get_simulation_time(state); digits = 3)
    evaluation_time = round(get_evaluation_time(state); digits = 3)
    println("reproduction_time: $reproduction_time, simulation_time: $simulation_time, evaluation_time: $evaluation_time")
    close(file)
end

end