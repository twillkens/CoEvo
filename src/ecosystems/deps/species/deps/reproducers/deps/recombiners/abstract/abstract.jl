module Abstract

export Recombiner, recombine

abstract type Recombiner end

using .....Ecosystems.Utilities.Counters: Counter
using ....Individuals.Abstract: Individual
using Random: AbstractRNG

function recombine(
    recombiner::Recombiner,
    ::AbstractRNG, 
    ::Counter, 
    ::Vector{Individual}
)
    throw(ErrorException("recombine not implemented for $recombiner"))
end

end