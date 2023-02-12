export hopcroft
export minimize
export FSMPheno

struct SetPack
    Y::Set{String}
    isect::Set{String}
    diff::Set{String}
end

function getX(c::Bool, A::Set{String}, links::LinkDict)
    X = Set{String}()
    for ((origin, bit), dest) in links
        if bit == c && dest in A
            push!(X, origin)
        end
    end
    X
end

function getpacks(P::Set{Set{String}}, X::Set{String})
    Ys = Set{SetPack}()
    for Y in P
        isect = intersect(X, Y)
        diff = setdiff(Y, X)
        if length(isect) > 0 && length(diff) > 0
            pack = SetPack(Y, isect, diff)
            push!(Ys, pack)
        end
    end
    Ys
end

function handlepack!(pack::SetPack, P::Set{Set{String}}, W::Set{Set{String}})
    pop!(P, pack.Y)
    push!(P, pack.isect)
    push!(P, pack.diff)
    if pack.Y in W
        pop!(W, pack.Y)
        push!(W, pack.isect)
        push!(W, pack.diff)
    else
        if length(pack.isect) <= length(pack.diff)
            push!(W, pack.isect)
        else
            push!(W, pack.diff)
        end
    end
end

function gettemp(new::Set{String}, links::LinkDict)
    temp = Set{String}()
    for q in new
        for c in [true, false]
            push!(temp, links[(q, c)])
        end
    end
    temp
end

function prune(fsm::FSMIndiv)
    reachable = Set{String}([fsm.start])
    new = Set{String}([fsm.start])
    ones = copy(fsm.ones)
    zeros = copy(fsm.zeros)
    links = copy(fsm.links)

    while true
        temp = gettemp(new, links)
        new = setdiff(temp, reachable)
        union!(reachable, new)
        length(new) > 0 || break
    end
    intersect!(ones, reachable)
    intersect!(zeros, reachable)
    for ((origin, bool), dest) in links
        if !(origin in reachable) || !(dest in reachable)
            pop!(links, (origin, bool))
        end
    end
    ones, zeros, links
end

function hopcroft(fsm::FSMIndiv; doprune::Bool=true)
    ones, zeros, links = doprune ? prune(fsm) : (copy(fsm.ones), copy(fsm.zeros), copy(fsm.links))

    P = Set([ones, zeros])
    W = Set([ones, zeros])
    while length(W) > 0
        A = pop!(W)
        for c in [true, false]
            X = getX(c, A, links)
            [handlepack!(pack, P, W) for pack in getpacks(P, X)]
        end
    end
    P
end

function mergepart(part::Set{String})
    s = join(sort(collect(part)), "/")
    contains(s, "/") ? s : string(s, "/")
end

function make_mergemap(fsm::FSMIndiv, P::Set{Set{String}})
    merged = map(mergepart, collect(P))
    mergemap = Dict{String, String}()
    for s in vcat(collect(fsm.ones), collect(fsm.zeros))
        for m in merged
            if s in split(m, "/")
                push!(mergemap, s => m)
            end
        end
    end
    mergemap
end

function FSMIndiv(fsm::FSMIndiv, P::Set{Set{String}})
    mergemap = make_mergemap(fsm, P)
    filter!(s -> length(s) > 0, P)
    newones = StateSet()
    newzeros = StateSet()
    newlinks = LinkDict()
    newstart = ""
    for part in P
        oldorigin = rand(part)
        neworigin = mergepart(part)
        newstart = fsm.start in part ? neworigin : newstart
        newset = oldorigin in fsm.ones ? newones : newzeros
        push!(newset, neworigin)
        oldtruedest = fsm.links[(oldorigin, true)]
        newlinks[(neworigin, true)] = mergemap[oldtruedest]
        oldfalsedest = fsm.links[(oldorigin, false)]
        newlinks[(neworigin, false)] = mergemap[oldfalsedest]
    end
    if newstart == ""
        throw(ArgumentError("Minimization failed"))
    end
    geno = FSMGeno(fsm.ikey, newstart, newones, newzeros, newlinks)
    FSMIndiv(fsm.ikey, geno)
end

function minimize(fsm::FSMIndiv; doprune::Bool=true)
    P = hopcroft(fsm, doprune = doprune)
    FSMIndiv(fsm, P)
end


