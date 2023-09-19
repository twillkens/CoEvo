export EvoState

mutable struct SpawnCounter
    iid::Int
    gid::Int
end

function SpawnCounter()
    SpawnCounter(1, 1)
end


function iid!(sc::SpawnCounter)
    iid = sc.iid
    sc.iid += 1
    iid
end

function gids!(sc::SpawnCounter, n::Int)
    [gid!(sc) for _ in 1:n]
end

function iids!(sc::SpawnCounter, n::Int)
    [iid!(sc) for _ in 1:n]
end

function Base.show(io::IO, i::UInt16)
    print(io, Int(i))
end

function Base.show(io::IO, i::UInt32)
    print(io, Int(i))
end
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