module Interfaces

export replace

using Random: AbstractRNG
using DataStructures: OrderedDict

using .....Individuals.Abstract: Individual
using .....Species.Evaluators.Abstract: Evaluation

function replace(
    replacer::Replacer,
    ::AbstractRNG, 
    ::OrderedDict{<:Individual, <:Evaluation},
    ::OrderedDict{<:Individual, <:Evaluation}
)
    throw(ErrorException("replace not implemented for $replacer"))
end

end