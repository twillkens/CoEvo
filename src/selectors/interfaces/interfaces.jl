module Interfaces

export select

using Random: AbstractRNG
using DataStructures: OrderedDict
using ...Individuals.Abstract: Individual
using ...Species.Abstract: AbstractSpecies
using ...Evaluators.Abstract: Evaluation
using ..Selectors.Abstract: Selector

function select(
    selector::Selector,
    ::AbstractRNG, 
    new_population::Vector{Individual},
    evaluation::Evaluation
)::Vector{Individual}
    throw(ErrorException(
        "Selector $selector not implemented for $evaluation")
    )
end

end