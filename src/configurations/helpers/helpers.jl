module Helpers

using JLD2: @save
using ..Configurations.Abstract: Configuration
using ..Configurations.Interfaces: make_ecosystem_creator

import ...Ecosystems.Interfaces: evolve!

function evolve!(configuration::Configuration; n_generations::Int = 100)
    ecosystem_creator = make_ecosystem_creator(configuration)
    archive_path = ecosystem_creator.archiver.archive_path
    dir_path = dirname(archive_path)

    # Check if the file exists
    if isfile(archive_path)
        throw(ArgumentError("File already exists: $archive_path"))
    end
    mkpath(dir_path)
    @save archive_path configuration = configuration
    ecosystem = evolve!(ecosystem_creator, n_generations = n_generations)
    return ecosystem
end

end