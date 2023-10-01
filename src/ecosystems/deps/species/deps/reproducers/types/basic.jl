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
    RC <: Recombiner,
} <: Reproducer
    replacer::RP
    selector::S
    recombiner::RC
end

function reproduce(
    reproducer::BasicReproducer,
    mutator::Mutator,
    rng::AbstractRNG, 
    indiv_id_counter::Counter,  
    species::AbstractSpecies,
    evaluation::Evaluation
)
    new_pop = replace(reproducer.replacer, rng, species, evaluation)
    parents = select(reproducer.selector, rng, species, evaluation)
    new_children = recombine(reproducer.recombiner, rng, indiv_id_counter, parents)
    for mutator in species_creator.indiv_creator.mutators
        new_children = mutate(mutator, rng, gene_id_counter, new_children)
    end

    return new_children
end

end