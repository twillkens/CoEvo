module Interfaces

export replace

using DataStructures: OrderedDict

using ..Abstract: Individual, Evaluation, Replacer, AbstractRNG

function replace(
    replacer::Replacer,
    ::AbstractRNG, 
    ::OrderedDict{<:Individual, <:Evaluation},
    ::OrderedDict{<:Individual, <:Evaluation}
)
    throw(ErrorException("replace not implemented for $replacer"))
end

end