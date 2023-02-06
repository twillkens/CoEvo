export Species

struct Species{I <: Individual}
    spkey::String
    pop::Set{I}
    parents::Vector{Int}
    children::Set{I}
end

function Species(spkey::String, pop::Set{I}) where {I <: Individual}
    Species(spkey, pop, Int[], Set{I}())
end


function Species(spkey::String, pop::Set{I}, children::Set{I}) where {I <: Individual}
    Species(spkey, pop, Int[], children)
end

