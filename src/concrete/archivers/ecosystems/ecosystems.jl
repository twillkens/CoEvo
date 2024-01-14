module Ecosystems

export EcosystemArchiver 

import ....Interfaces: archive!

using HDF5: h5open, File
using ....Abstract
using ....Interfaces

struct EcosystemArchiver <: Archiver end

function archive!(::EcosystemArchiver, state::State)
    ecosystem_dict = convert_to_dictionary(state.ecosystem)
    generation = state.generation
    archive_path = "$(state.archive_directory)/generations/$generation.h5"
    file = h5open(archive_path, "w")
    base_path = "ecosystem"
    archive!(file, base_path, ecosystem_dict)
    file["valid"] = true
    close(file)
    flush(stdout)
end

end