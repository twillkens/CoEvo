export hopcroft
export minimize
export FSMPheno

struct SetPack{T}
    Y::Set{T}
    isect::Set{T}
    diff::Set{T}
end

function getX(c::Bool, A::Set{T}, links::Dict{Tuple{T, Bool}, T}) where T
    X = Set{T}()
    for ((origin, bit), dest) in links
        if bit == c && dest in A
            push!(X, origin)
        end
    end
    X
end

function getpacks(P::Set{Set{T}}, X::Set{T}) where T
    Ys = Set{SetPack{T}}()
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

function handlepack!(pack::SetPack, P::Set{Set{T}}, W::Set{Set{T}}) where T
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

function gettemp(new::Set{T}, links::Dict{Tuple{T, Bool}, T}) where T
    temp = Set{T}()
    for q in new
        for c in [true, false]
            push!(temp, links[(q, c)])
        end
    end
    temp
end

function prune(fsm::FSMGeno)
    reachable = Set([fsm.start])
    new = Set([fsm.start])
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

function hopcroft(fsm::FSMGeno; doprune::Bool=true)
    ones, zeros, links = doprune ? 
        prune(fsm) : 
        (copy(fsm.ones), copy(fsm.zeros), copy(fsm.links))
    P, W = Set([ones, zeros]), Set([ones, zeros])
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

function make_mergemap(fsm::FSMGeno, P::Set{Set{String}})
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

function mergeP(fsm::FSMGeno{String}, P::Set{Set{String}})
    mergemap = make_mergemap(fsm, P)
    filter!(s -> length(s) > 0, P)
    newones = Set{String}()
    newzeros = Set{String}()
    newlinks = Dict{Tuple{String, Bool}, String}()
    newstart = nothing
    for part in P
        oldorigin = first(part)
        neworigin = mergepart(part)
        newstart = fsm.start in part ? neworigin : newstart
        newset = oldorigin in fsm.ones ? newones : newzeros
        push!(newset, neworigin)
        oldtruedest = fsm.links[(oldorigin, true)]
        newlinks[(neworigin, true)] = mergemap[oldtruedest]
        oldfalsedest = fsm.links[(oldorigin, false)]
        newlinks[(neworigin, false)] = mergemap[oldfalsedest]
    end
    if newstart === nothing
        throw(ArgumentError("Minimization failed"))
    end
    FSMGeno(newstart, newones, newzeros, newlinks), mergemap
end

function mergeP(fsm::FSMGeno{<:Real}, P::Set{<:Set{<:Real}})
    P = filter(s -> length(s) > 0, P)
    mm = Dict(x => i for (i, part) in enumerate(P) for x in part if length(part) > 0)
    newstart = mm[fsm.start]
    newones = Set(mm[x] for x in fsm.ones if x in keys(mm))
    newzeros = Set(mm[x] for x in fsm.zeros if x in keys(mm))
    newlinks = Dict(
        (mm[s], w) => mm[d]
        for ((s, w), d) in fsm.links
        if s in keys(mm) && d in keys(mm)
    )
    FSMGeno(newstart, newones, newzeros, newlinks), mm
end

function minimize(fsm::FSMGeno; doprune::Bool = true, getmm::Bool = false)
    P = hopcroft(fsm, doprune = doprune)
    geno, mm = mergeP(fsm, P)
    getmm ? (geno, mm) : geno
end

function minimize(fsm::FSMIndiv; doprune::Bool=true)
    mingeno = minimize(fsm.geno, doprune = doprune)
    FSMIndiv(fsm.ikey, fsm.geno, mingeno, fsm.pids)
end


