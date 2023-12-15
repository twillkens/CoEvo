export mutate

function mutate(
    mutator::Mutator, 
    random_number_generator::AbstractRNG, 
    gene_id_counter::Counter,
    genotype::Genotype
)::Genotype
    throw(ErrorException("Default mutation for $mutator not implemented for $genotype."))
end

function mutate(
    mutator::Mutator,
    random_number_generator::AbstractRNG,
    gene_id_counter::Counter,
    individuals::Vector{I},
) where {I <: Individual}
    new_individuals = Vector{I}(undef, length(individuals))
    
    # make a new rng for each thread that uses the seed of the main rng
    # so that there is perfect reproducibility of the results

    # Create a vector of seeds for each individual
    seeds = rand(random_number_generator, 1:2^32, length(individuals))

    
    Threads.@threads for i in eachindex(individuals)
        ind_rng = StableRNG(seeds[i])
        new_individuals[i] = BasicIndividual(
            individuals[i].id,
            mutate(mutator, ind_rng, gene_id_counter, individuals[i].genotype),
            individuals[i].parent_ids
        )
    end

    return new_individuals
end
