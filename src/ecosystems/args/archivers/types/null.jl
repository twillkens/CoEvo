
struct NullArchiver <: Archiver end

(archiver::NullArchiver)(args...; kwargs...) = nothing