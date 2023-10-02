module Interfaces

export replace

using Random: AbstractRNG
using ...Species.Individuals: Individual
using ...Species.Evaluators.Abstract: Evaluation
using ..Replacers.Abstract: Replacer
using ...Species.Abstract: AbstractSpecies

function replace(
    replacer::Replacer,
    rng::AbstractRNG, 
    species::AbstractSpecies,
    evaluation::Evaluation
)::Dict{Int, Individual}
    throw(ErrorException("replace not implemented for $replacer"))
end

end