module Recombiners

export CloneRecombiner

using Random
using ...CoEvo: Recombiner
using ...CoEvo.Utilities: Counter
using ..Individuals: Indiv, Individual

Base.@kwdef struct CloneRecombiner <: Recombiner
end

function(r::CloneRecombiner)(
    ::AbstractRNG, indiv_id_counter::Counter, parents::Vector{<:Individual}
)
    [Indiv(next!(sc), parent.geno, parent.id) for parent in parents]
end

end