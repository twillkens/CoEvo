module Modes

export ModesArchiveConfiguration

using ...ArchiveConfigurations: ArchiveConfiguration

Base.@kwdef struct ModesArchiveConfiguration <: ArchiveConfiguration
    id::String
    archive_interval::Int
    modes_interval::Int
    archivers::Vector{String}
end

end