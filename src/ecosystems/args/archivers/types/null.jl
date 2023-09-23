using ...CoEvo.Abstract: Archiver

struct NullArchiver <: Archiver end

(archiver::NullArchiver)(args...; kwargs...) = nothing