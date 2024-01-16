module Ecosystems

export EcosystemArchiver 

import ....Interfaces: archive!

using HDF5: h5open, File
using ....Abstract
using ....Interfaces
using ....Utilities

Base.@kwdef struct EcosystemArchiver <: Archiver 
    valid_flag::Bool = true
end

function archive!(archiver::EcosystemArchiver, state::State)
    archive_directory = state.configuration.archive_directory
    if !ispath("$archive_directory/generations")
        mkpath("$archive_directory/generations")
    end
    #println("ecosystem_before_save = $(state.ecosystem)")
    generation = state.generation
    archive_path = "$archive_directory/generations/$generation.h5"
    file = h5open(archive_path, "w")
    state_dict = convert_to_dict(state, state.configuration)
    save_dict_to_hdf5!(file, "/", state_dict)
    file["valid"] = archiver.valid_flag
    close(file)
    flush(stdout)
end

end