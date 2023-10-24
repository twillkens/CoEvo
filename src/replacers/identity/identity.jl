module Identity

export IdentityReplacer

import ..Replacers: replace 

using Random: AbstractRNG
using ...Species: AbstractSpecies
using ...Evaluators: Evaluation
using ..Replacers: Replacer

struct IdentityReplacer <: Replacer end

function replace(
    ::IdentityReplacer,
    ::AbstractRNG, 
    species::AbstractSpecies,
    ::Evaluation
)
    population = species.population
    return population
end

end