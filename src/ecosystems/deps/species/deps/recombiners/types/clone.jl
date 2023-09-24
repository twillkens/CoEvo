using Random: AbstractRNG
using DataStructures: OrderedDict
using ....CoEvo.Abstract: Recombiner, Individual, Evaluation
using ..Utilities: Counter, next!


Base.@kwdef struct CloneRecombiner <: Recombiner end

function(recombiner::CloneRecombiner)(
    ::AbstractRNG, indiv_id_counter::Counter, parents::OrderedDict{I, <:Evaluation}
) where {I <: Individual}
    [I(next!(indiv_id_counter), parent.geno, parent.id) for parent in keys(parents)]
end
