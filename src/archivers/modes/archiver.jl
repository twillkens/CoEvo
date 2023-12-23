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
    if archiver.archive_interval == 0 || generation % archiver.archive_interval != 0
        return
    end
    complexity = measure_complexity(state)
    change = measure_change(state)
    novelty = measure_novelty(state)
    ecology = measure_ecology(state)
    measurements = merge(complexity, change, novelty, ecology)
    base_path = "generations/$generation/modes"
    file = h5open(archiver.h5_path, "r+")
    # TODO: Add measurements to HDF5 file.
    add_measurements_to_hdf5(file, base_path, measurements)
    close(file)
end

