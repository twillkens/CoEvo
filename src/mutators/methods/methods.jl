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
    random_number_generator::AbstractRNG,
    gene_id_counter::Counter,
    individuals::Vector{<:Individual},
)
    individuals = [
        Individual(
            individual.id,
            mutate(mutator, random_number_generator, gene_id_counter, individual.genotype),
            individual.parent_ids
        ) for individual in individuals
    ]

    return individuals
end

end