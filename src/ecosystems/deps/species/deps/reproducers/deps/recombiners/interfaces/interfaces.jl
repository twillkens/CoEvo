module Interfaces

using .....Ecosystems.Utilities.Counters: Counter
using ..Abstract: Individual, AbstractRNG, Recombiner

function recombine(
    recombiner::Recombiner,
    ::AbstractRNG, 
    ::Counter, 
    ::Vector{Individual}
)
    throw(ErrorException("recombine not implemented for $recombiner"))
end

end