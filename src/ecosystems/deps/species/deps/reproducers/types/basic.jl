module Basic

export BasicReproducer

using DataStructures: OrderedDict

using .....Ecosystems.Utilities.Counters: Counter
using ..Abstract: Individual, Evaluation, AbstractRNG, Reproducer
using ..Replacers.Abstract: Replacer
using ..Selectors.Abstract: Selector
using ..Recombiners.Abstract: Recombiner

import ..Interfaces: reproduce

struct BasicReproducer{
    RP <: Replacer,
    S <: Selector,
    RC <: Recombiner
} <: Reproducer
    replacer::RP
    selector::S
    recombiner::RC
end

function reproduce(
    reproducer::BasicReproducer,
    rng::AbstractRNG, 
    indiv_id_counter::Counter,  
    pop_evals::OrderedDict{<:Individual, <:Evaluation},
    children_evals::OrderedDict{<:Individual, <:Evaluation}
)
    new_pop_evals = replace(reproducer.replacer, rng, pop_evals, children_evals)
    parents = select(reproducer.selector, rng, new_pop_evals)
    new_children = recombine(reproducer.recombiner, rng, indiv_id_counter, parents)
    return new_children
end

end