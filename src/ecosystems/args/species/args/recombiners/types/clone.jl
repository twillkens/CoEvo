using Random: AbstractRNG
using ....CoEvo.Abstract: Recombiner, Individual
using ..Utilities: Counter

Base.@kwdef struct CloneRecombiner <: Recombiner end

function(recombiner::CloneRecombiner)(
    ::AbstractRNG, indiv_id_counter::Counter, parents::Vector{I}
) where {I <: Individual}
    [I(next!(sc), parent.geno, parent.id) for parent in parents]
end