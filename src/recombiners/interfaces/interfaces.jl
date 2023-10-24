module Interfaces

using Random: AbstractRNG
using ...Counters: Counter
using ...Individuals.Abstract: Individual
using ..Recombiners.Abstract: Recombiner

function recombine(
    recombiner::Recombiner,
    ::AbstractRNG, 
    ::Counter, 
    ::Vector{Individual}
)
    throw(ErrorException("recombine not implemented for $recombiner"))
end

end