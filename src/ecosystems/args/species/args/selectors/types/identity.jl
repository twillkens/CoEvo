
# abstract type Selector end
struct IdentitySelector <: Selector
end

function(s::IdentitySelector)(::AbstractRNG, pop::Vector{<:Individual})
    pop
end