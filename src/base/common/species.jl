export Species

struct Species{I <: Individual}
    spkey::String
    pop::Set{I}
    parents::Vector{I}
    children::Set{I}
end

function Species(spkey::String, pop::Set{I}) where {I <: Individual}
    Species(spkey, pop, I[], Set{I}())
end
