export LingPredMutator
export addstate, rmstate, changelink, changelabel

Base.@kwdef struct LingPredMutator <: Mutator
    nchanges::Int = 1
    probs::Dict{Function, Float64} = Dict(
        addstate => 0.25,
        rmstate => 0.25,
        changelink => 0.25,
        changelabel => 0.25
    )
end

function(m::LingPredMutator)(rng::AbstractRNG, sc::SpawnCounter, fsm::FSMIndiv,) 
    fns = sample(rng, collect(keys(m.probs)), Weights(collect(values(m.probs))), m.nchanges)
    geno = fsm.geno
    for fn in fns
        geno = fn(rng, sc, geno)
    end
    FSMIndiv(fsm.ikey, geno, minimize(geno), fsm.pids)
end

function randfsmstate(
    rng::AbstractRNG, fsm::FSMGeno{T};
    include::Set{T} = Set{T}(), 
    exclude::Set{T} = Set{T}()
) where T
    nodes = union(fsm.ones, fsm.zeros, include)
    nodes = setdiff(nodes, exclude)
    rand(rng, nodes)
end

# add state

function newstate!(sc::SpawnCounter, ::FSMGeno{String})
    string(gid!(sc))
end

function newstate!(sc::SpawnCounter, ::FSMGeno{UInt32})
    gid!(sc)
end

function newstate!(sc::SpawnCounter, ::FSMGeno{Int})
    Int(gid!(sc))
end

function addstate(rng::AbstractRNG, sc::SpawnCounter, fsm::FSMGeno)
    label = rand(rng, Bool)
    newstate = newstate!(sc, fsm)
    truedest = randfsmstate(rng, fsm; include = Set([newstate]))
    falsedest = randfsmstate(rng, fsm, include = Set([newstate]))
    addstate(fsm, newstate, label, truedest, falsedest)
end

function addstate(
    fsm::FSMGeno{T}, newstate::T, label::Bool, truedest::T, falsedest::T
) where T
    s = Set([newstate])
    ones, zeros = label ? (union(fsm.ones, s), fsm.zeros) : (fsm.ones, union(fsm.zeros, s))
    newlinks = Dict((newstate, true) => truedest, (newstate, false) => falsedest)
    FSMGeno(fsm.start, ones, zeros, merge(fsm.links, newlinks))
end

# remove state

function getnew(rng::AbstractRNG, fsm::FSMGeno{T}, todelete::T) where T
    newstart = todelete == fsm.start ?
        randfsmstate(rng, fsm; exclude = Set([todelete])) : fsm.start
    newlinks = Dict{Tuple{T, Bool}, T}()
    for ((origin, bool), dest) in fsm.links
        if dest == todelete && origin != todelete
            newdest = fsm.links[(todelete, bool)]
            newdest = newdest == todelete ? origin : newdest
            push!(newlinks, (origin, bool) => newdest)
        end
    end
    newstart, newlinks
end

function rmstate(rng::AbstractRNG, ::SpawnCounter, fsm::FSMGeno)
    if length(fsm.ones) + length(fsm.zeros) < 2 return fsm end
    todelete = randfsmstate(rng, fsm)
    start, newlinks = getnew(rng, fsm, todelete)
    rmstate(fsm, todelete, start, newlinks)
end

function rmstate(rng::AbstractRNG, fsm::FSMGeno{T}, todelete::T) where T
    if length(fsm.ones) + length(fsm.zeros) < 2 return fsm end
    start, newlinks = getnew(rng, fsm, todelete)
    rmstate(fsm, todelete, start, newlinks)
end

function rmstate(fsm::FSMGeno{T}, todelete::T, start::T, newlinks::Dict{Tuple{T, Bool}, T}
) where T
    ones, zeros = todelete ∈ fsm.ones ?
        (filter(s -> s != todelete, fsm.ones), fsm.zeros) :
        (fsm.ones, filter(s -> s != todelete, fsm.zeros))
    links = merge(filter(p -> p[1][1] != todelete, fsm.links), newlinks)
    FSMGeno(start, ones, zeros, links)
end


# change link


function changelink(rng::AbstractRNG, ::SpawnCounter, fsm::FSMGeno)
    state = randfsmstate(rng, fsm)
    newdest = randfsmstate(rng, fsm)
    bit = rand(rng, Bool)
    changelink(fsm, state, newdest, bit)
end

function changelink(fsm::FSMGeno{T}, state::T, newdest::T, bit::Bool) where T
    links = merge(fsm.links, Dict((state, bit) => newdest))
    FSMGeno(fsm.start, fsm.ones, fsm.zeros, links)
end

# change label

function changelabel(rng::AbstractRNG, ::SpawnCounter, fsm::FSMGeno)
    state = randfsmstate(rng, fsm)
    changelabel(fsm, state)
end

function changelabel(fsm::FSMGeno{T}, state::T) where T
    s = Set([state])
    ones, zeros = state ∈ fsm.ones ?
        (setdiff(fsm.ones, s), union(fsm.zeros, s)) :
        (union(fsm.ones, s), setdiff(fsm.zeros, s))
    FSMGeno(fsm.start, ones, zeros, fsm.links)
end
