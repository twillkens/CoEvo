module Archivists

using ...CoEvo: Archivist, Individual, ArchivistConfiguration

Base.@kwdef struct DefaultArchivist <: Archivist end

Base.@kwdef struct ArchivistCfg <: ArchivistConfiguration
    log_interval::Int = 1
end

end