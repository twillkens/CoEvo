module Replacers

export IdentityReplacer
# export TruncationReplacer
# export GenerationalReplacer

include("types/identity.jl")
# include("types/truncation.jl")
# include("types/generational.jl")

using Random
using ....CoEvo.Abstract: Replacer, Evaluation, AbstractSpecies


function(replacer::Replacer)(
    rng::AbstractRNG, 
    species::AbstractSpecies,
    pop_evals::Dict{Int, <:Evaluation},
    children_evals::Dict{Int, <:Evaluation},
)
    new_pop_indices = replacer(rng, collect(values(pop_evals)), collect(values(children_evals)))
    new_pop = filter(
        (indiv_id, _) -> indiv_id in new_pop_indices, 
        merge(species.pop, species.children)
    )
    return new_pop
end


end