module Generational

export GenerationalReplacer

using DataStructures: OrderedDict

using Random: AbstractRNG
using ....Species.Replacers.Abstract: Replacer
using ....Species.Individuals: Individual
using ....Species.Abstract: AbstractSpecies
using ....Species.Evaluators.Types: ScalarFitnessEvaluation

import ...Interfaces: replace


Base.@kwdef struct GenerationalReplacer <: Replacer
    n_elite::Int = 0
end

function replace(
    replacer::GenerationalReplacer,
    ::AbstractRNG, 
    species::AbstractSpecies,
    evaluation::ScalarFitnessEvaluation
)
    if isempty(species.children)
        return species.pop
    end

    
    pop_ids = filter(
        (indiv_id, fitness) -> indiv_id in species.pop, keys(evaluation.fitnesses)
    )
    children_ids = filter(
        (indiv_id, fitness) -> indiv_id in species.children, keys(evaluation.fitnesses)
    )
    elite_ids = pop_ids[1:replacer.n_elite]
    n_children = length(species.pop) - replacer.n_elite
    children_ids = children_ids[1:n_children]
    new_pop = Dict(
        id => indiv for (id, indiv) in merge(species.pop, species.children) 
        if id in Set([elite_ids ; children_ids]))

    return new_pop
end

end