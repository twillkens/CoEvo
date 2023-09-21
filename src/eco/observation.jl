abstract type Observation end
abstract type ObservationConfiguration end
# A NullObs is an observation that does nothing. It is used when no observation
# of phenotypic interaction is needed.
struct NullObs <: Observation end

# A NullObsCfg is a configuration for a NullObs. It is used when no observation
# of phenotypic interaction is needed.
struct NullObsCfg <: ObservationConfiguration end

# When called, a NullObsCfg ignores whatever arguments are passed and returns a NullObs.
function(cfg::NullObsCfg)(args...; kwargs...)
    NullObs()
end
