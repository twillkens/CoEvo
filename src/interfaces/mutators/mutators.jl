export mutate, mutate!

using ..Abstract

function mutate(
    mutator::Mutator, 
    rng::AbstractRNG, 
    gene_id_counter::Counter,
    genotype::Genotype
)::Genotype
    throw(ErrorException("Default mutation for $mutator not implemented for $genotype."))
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

function mutate!(mutator::Mutator, individuals::Vector{<:Individual}, state::State)
    for individual in individuals
        mutate!(mutator, individual.genotype, state)
    end
end