module Observations

export NullObsCfg

using ...CoEvo: Observation, ObservationConfiguration

"""
    NullObs <: Observation

Represents a null observation that effectively does nothing. 
Typically used in scenarios where no phenotypic interaction observation is needed.
"""
struct NullObs <: Observation end

"""
    NullObsCfg <: ObservationConfiguration

A configuration for `NullObs`. 
It signifies that no specific configuration for phenotypic interaction observation is necessary.
"""
struct NullObsCfg <: ObservationConfiguration end

"""
    (cfg::NullObsCfg)(args...; kwargs...) -> NullObs

Creates a `NullObs` instance, effectively ignoring any arguments passed.

# Arguments
- `cfg::NullObsCfg`: Configuration specifying that a null observation should be produced.
- `args...; kwargs...`: Arbitrary arguments and keyword arguments, which are ignored.

# Returns
- An instance of `NullObs`.
"""
function(cfg::NullObsCfg)(args...; kwargs...)
    NullObs()
end

end
