export NullObs, NullObsConfig

struct NullObs <: Observation
end

struct NullObsConfig <: ObsConfig end

function(cfg::NullObsConfig)(args...; kwargs...)
    NullObs()
end