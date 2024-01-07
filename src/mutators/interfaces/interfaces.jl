export mutate

using ..Abstract.States: State

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


using ..Individuals.Modes: ModesIndividual

function mutate(
    mutator::Mutator,
    rng::AbstractRNG,
    gene_id_counter::Counter,
    individuals::Vector{<:ModesIndividual},
)
    individuals = [
        ModesIndividual(
            individual.id,
            individual.parent_id,
            individual.tag,
            mutate(mutator, rng, gene_id_counter, individual.genotype),
        ) for individual in individuals
    ]

    return individuals
end

function mutate(mutator::Mutator, individuals::Vector{<:Individual}, state::State)
    individuals = mutate(
        mutator,
        state.rng,
        state.gene_id_counter,
        individuals
    )
    return individuals
end