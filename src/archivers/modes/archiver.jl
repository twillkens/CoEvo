export ModesArchiver

import ..Archivers: archive!

using ...Abstract.States: State, get_generation
using ...Archivers.Utilities: add_measurements_to_hdf5
using ...Archivers: Archiver
using HDF5: h5open

struct ModesArchiver <: Archiver
    archive_interval::Int
    h5_path::String
end

function archive!(archiver::ModesArchiver, state::State)
    generation = get_generation(state)
    do_not_archive = archiver.archive_interval == 0
    is_archive_interval = get_generation(state) == 1 ||
        get_generation(state) % archiver.archive_interval == 0
    if do_not_archive || !is_archive_interval
        return
    end
    complexity = measure_complexity(state)
    mean_value   = round(complexity["complexity"]["mean"]; digits = 3)
    max_value   = round(complexity["complexity"]["maximum"]; digits = 3)
    min_value   = round(complexity["complexity"]["minimum"]; digits = 3)
    println("complexity: mean: $mean_value, min: $min_value, max: $max_value")
    change = measure_change(state)
    novelty = measure_novelty(state)
    ecology = measure_ecology(state)
    measurements = merge(complexity, change, novelty, ecology)
    println("change: $(change["change"]), novelty: $(novelty["novelty"]), ecology: $(ecology["ecology"])")
    base_path = "generations/$generation/modes"
    file = h5open(archiver.h5_path, "r+")
    add_measurements_to_hdf5(file, base_path, measurements)
    close(file)
end

