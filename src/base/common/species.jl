export Species
export allindivs

struct Species{I <: Individual}
    spid::Symbol
    pop::Set{I}
    children::Set{I}
end

function allindivs(sp::Species)
    union(sp.pop, sp.children)
end

function allindivs(allsp::Set{<:Species})
    union([allindivs(sp) for sp in allsp]...)
end

function allindivs(allsp::Set{<:Species}, spid::Symbol)
    spd = Dict(sp.spid => sp for sp in allsp)
    allindivs(spd[spid])
end

function Species(spid::Symbol, pop::Set{I}) where {I <: Individual}
    Species(spid, pop, Set{I}())
end

function Species(spid::Symbol, pop::Set{I}, ::Set{Any}) where {I <: Individual}
    Species(spid, pop, Set{I}())
end

