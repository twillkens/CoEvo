module Interfaces

using Random: AbstractRNG
using .....Ecosystems.Utilities.Counters: Counter
using ..Abstract: Recombiner
using ...Species.Individuals: Individual

function recombine(
    recombiner::Recombiner,
    ::AbstractRNG, 
    ::Counter, 
    ::Vector{Individual}
)
    throw(ErrorException("recombine not implemented for $recombiner"))
end

end