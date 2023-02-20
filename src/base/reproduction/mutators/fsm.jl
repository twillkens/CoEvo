export LingPredMutator
export addstate, rmstate, changelink, changelabel

Base.@kwdef struct LingPredMutator <: Mutator
    rng::AbstractRNG
    sc::SpawnCounter
    nchanges::Int = 1
    probs::Dict{Function, Float64} = Dict(
        addstate => 0.25,
        rmstate => 0.25,
        changelink => 0.25,
        changelabel => 0.25
    )
end

function(m::LingPredMutator)(fsm::FSMIndiv)
    fns = sample(m.rng, collect(keys(m.probs)), Weights(collect(values(m.probs))), m.nchanges)
    for fn in fns
        fsm = fn(m, fsm)
    end
    fsm
end

function randstate(rng::AbstractRNG, fsm::FSMIndiv)
    rand(rng, union(fsm.ones, fsm.zeros))
end

function randstate(
    rng::AbstractRNG, fsm::FSMIndiv;
    include::Set{String} = Set{String}(), 
    exclude::Set{String} = Set{String}()
)
    nodes = union(fsm.ones, fsm.zeros, include)
    nodes = setdiff(nodes, exclude)
    rand(rng, nodes)
end

function newstate!(m::LingPredMutator)
    string(gid!(m.sc))
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


function addstate(m::LingPredMutator, fsm::FSMIndiv)
    label = rand(m.rng, Bool)
    newstate = newstate!(m)
    truedest = randstate(m.rng, fsm; include = Set([newstate]))
    falsedest = randstate(m.rng, fsm, include = Set([newstate]))
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
        randstate(rng, fsm; exclude = Set([todelete])) : fsm.start
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

function rmstate(m::LingPredMutator, fsm::FSMIndiv)
    if length(union(fsm.ones, fsm.zeros)) < 2 return fsm end
    todelete = randstate(m.rng, fsm)
    start, newlinks = getnew(m.rng, fsm, todelete)
    rmstate(fsm, todelete, start, newlinks)
end

function changelink(m::LingPredMutator, fsm::FSMIndiv)
    state = randstate(m.rng, fsm)
    newdest = randstate(m.rng, fsm)
    bit = rand(m.rng, Bool)
    changelink(fsm, state, newdest, bit)
end

function changelink(fsm::FSMIndiv, state::String, newdest::String, bit::Bool)
    links = merge(fsm.links, Dict((state, bit) => newdest))
    geno = FSMGeno(fsm.ikey, fsm.start, fsm.ones, fsm.zeros, links)
    FSMIndiv(fsm.ikey, geno, fsm.pids)
end

function changelabel(m::LingPredMutator, fsm::FSMIndiv)
    state = randstate(m.rng, fsm)
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


# function changelabel(fsm::FSMIndiv, state::String)
#     changelabel(fsm, Set([state]))
# end

