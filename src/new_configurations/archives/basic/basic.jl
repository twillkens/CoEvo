module Basic

export BasicArchiveConfiguration

using ...ArchiveConfigurations: ArchiveConfiguration

Base.@kwdef struct BasicArchiveConfiguration <: ArchiveConfiguration
    id::String
    archive_interval::Int
    archivers::Vector{String}
end

end