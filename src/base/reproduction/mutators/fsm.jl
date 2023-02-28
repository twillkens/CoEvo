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
    for fn in fns
        fsm = fn(rng, sc, fsm)
    end
    fsm
end

function randfsmstate(
    rng::AbstractRNG, fsm::FSMIndiv;
    include::Set{String} = Set{String}(), 
    exclude::Set{String} = Set{String}()
)
    nodes = union(fsm.ones, fsm.zeros, include)
    nodes = setdiff(nodes, exclude)
    rand(rng, nodes)
end

function newstate!(sc::SpawnCounter, )
    string(gid!(sc))
end

function addstate(
    fsm::FSMIndiv, newstate::String, label::Bool, truedest::String, falsedest::String
)
    s = Set([newstate])
    ones, zeros = label ? (union(fsm.ones, s), fsm.zeros) : (fsm.ones, union(fsm.zeros, s))
    newlinks = Dict((newstate, true) => truedest, (newstate, false) => falsedest)
    newgeno = FSMGeno(fsm.ikey, fsm.start, ones, zeros, merge(fsm.links, newlinks))
    FSMIndiv(fsm.ikey, newgeno, fsm.pids)
end

function addstate(rng::AbstractRNG, sc::SpawnCounter, fsm::FSMIndiv)
    label = rand(rng, Bool)
    newstate = newstate!(sc)
    truedest = randfsmstate(rng, fsm; include = Set([newstate]))
    falsedest = randfsmstate(rng, fsm, include = Set([newstate]))
    addstate(fsm, newstate, label, truedest, falsedest)
end

function rmstate(fsm::FSMIndiv, todelete::String, start::String, newlinks::LinkDict)
    ones, zeros = todelete ∈ fsm.ones ?
        (filter(s -> s != todelete, fsm.ones), fsm.zeros) :
        (fsm.ones, filter(s -> s != todelete, fsm.zeros))
    links = merge(filter(p -> p[1][1] != todelete, fsm.links), newlinks)
    geno = FSMGeno(fsm.ikey, start, ones, zeros, links)
    FSMIndiv(fsm.ikey, geno, fsm.pids)
end

function getnew(rng::AbstractRNG, fsm::FSMIndiv, todelete::String)
    newstart = todelete == fsm.start ?
        randfsmstate(rng, fsm; exclude = Set([todelete])) : fsm.start
    newlinks = LinkDict()
    for ((origin, bool), dest) in fsm.links
        if dest == todelete && origin != todelete
            newdest = fsm.links[(todelete, bool)]
            newdest = newdest == todelete ? origin : newdest
            push!(newlinks, (origin, bool) => newdest)
        end
    end
    newstart, newlinks
end

function rmstate(rng::AbstractRNG, ::SpawnCounter, fsm::FSMIndiv)
    if length(union(fsm.ones, fsm.zeros)) < 2 return fsm end
    todelete = randfsmstate(rng, fsm)
    start, newlinks = getnew(rng, fsm, todelete)
    rmstate(fsm, todelete, start, newlinks)
end

function changelink(rng::AbstractRNG, ::SpawnCounter, fsm::FSMIndiv)
    state = randfsmstate(rng, fsm)
    newdest = randfsmstate(rng, fsm)
    bit = rand(rng, Bool)
    changelink(fsm, state, newdest, bit)
end

function changelink(fsm::FSMIndiv, state::String, newdest::String, bit::Bool)
    links = merge(fsm.links, Dict((state, bit) => newdest))
    geno = FSMGeno(fsm.ikey, fsm.start, fsm.ones, fsm.zeros, links)
    FSMIndiv(fsm.ikey, geno, fsm.pids)
end

function changelabel(rng::AbstractRNG, ::SpawnCounter, fsm::FSMIndiv)
    state = randfsmstate(rng, fsm)
    changelabel(fsm, state)
end

function changelabel(fsm::FSMIndiv, state::String)
    s = Set([state])
    ones, zeros = state ∈ fsm.ones ?
        (setdiff(fsm.ones, s), union(fsm.zeros, s)) :
        (union(fsm.ones, s), setdiff(fsm.zeros, s))
    geno = FSMGeno(fsm.ikey, fsm.start, ones, zeros, fsm.links)
    FSMIndiv(fsm.ikey, geno, fsm.pids)
end