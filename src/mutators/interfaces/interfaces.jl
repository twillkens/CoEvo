export mutate

function mutate(
    mutator::Mutator, 
    rng::AbstractRNG, 
    gene_id_counter::Counter,
    genotype::Genotype
)::Genotype
    throw(ErrorException("Default mutation for $mutator not implemented for $genotype."))
end

function mutate(
    mutator::Mutator,
    rng::AbstractRNG,
    gene_id_counter::Counter,
    individuals::Vector{<:BasicIndividual},
)
    individuals = [
        BasicIndividual(
            individual.id,
            mutate(mutator, rng, gene_id_counter, individual.genotype),
            individual.parent_ids
        ) for individual in individuals
    ]

    return individuals
end
