export EvoState

Base.@kwdef struct EvoState
    rng::AbstractRNG
    counters::Dict{Symbol, SpawnCounter}
end

function EvoState(rng::AbstractRNG, spids::Vector{Symbol})
    counters = Dict(spid => SpawnCounter() for spid in spids)
    EvoState(rng, counters)
end

function EvoState(seed::Union{UInt64, Int}, spids::Vector{Symbol})
    rng = StableRNG(seed)
    EvoState(rng, spids)
end

function(cfg::IndivConfig)(es::EvoState, args...)
    cfg(es.rng, es.counters[cfg.spid], args...)
end