module Identity

export IdentityReplacer

import ...Interfaces: replace 

using Random: AbstractRNG
using ...Species.Abstract: AbstractSpecies
using ...Evaluators.Abstract: Evaluation
using ..Replacers.Abstract: Replacer

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