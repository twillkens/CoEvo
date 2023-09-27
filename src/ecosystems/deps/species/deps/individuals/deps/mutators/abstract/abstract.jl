module Abstract 

export Mutator, mutate

abstract type Mutator end

using Random: AbstractRNG

using .....Ecosystems.Utilities.Counters: Counter
using ...Individuals.Abstract: Individual

function mutate(::Mutator, ::AbstractRNG, ::Counter, indiv::Individual)
    throw(ErrorException("Mutator not implemented for type $(typeof(indiv))"))
end

end