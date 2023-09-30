module Interfaces

using ..Abstract: Individual, AbstractRNG, Reproducer, Evaluation, Reproducer

using DataStructures: OrderedDict
using ....Ecosystems.Utilities.Counters: Counter

function reproduce(
    reproducer::Reproducer,
    rng::AbstractRNG, 
    indiv_id_counter::Counter,  
    pop_evals::OrderedDict{<:Individual, <:Evaluation},
    children_evals::OrderedDict{<:Individual, <:Evaluation}
)::Vector{Individual}
    throw(ErrorException("reproduce not implemented for $reproducer"))

end

end

