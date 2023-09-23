using Random
using ....CoEvo.Abstract: Individual, Selector

# abstract type Selector end
struct IdentitySelector <: Selector
end

function(s::IdentitySelector)(::AbstractRNG, pop::Vector{<:Individual})
    pop
end