module Interfaces

export replace

using Random: AbstractRNG
using ...Individuals.Abstract: Individual
using ...Species.Abstract: AbstractSpecies
using ...Evaluators.Abstract: Evaluation
using ..Replacers.Abstract: Replacer

function replace(
    replacer::Replacer,
    random_number_generator::AbstractRNG, 
    species::AbstractSpecies,
    evaluation::Evaluation
)::Dict{Int, Individual}
    throw(ErrorException("replace not implemented for $replacer"))
end

end