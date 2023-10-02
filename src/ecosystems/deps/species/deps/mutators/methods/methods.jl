module Methods

export mutate

using Random: AbstractRNG
using ...Mutators.Interfaces: mutate
using ...Mutators.Abstract: Mutator
using .....Ecosystems.Utilities.Counters: Counter
using ...Species.Individuals: Individual

import ..Mutators.Interfaces: mutate

function mutate(
    mutator::Mutator,
    rng::AbstractRNG,
    gene_id_counter::Counter,
    individuals::Vector{<:Individual},
)
    individuals = [
        Individual(
            indiv.id,
            mutate(mutator, rng, gene_id_counter, indiv.geno),
            indiv.parent_ids
        ) for indiv in individuals
    ]

    return individuals
end

end