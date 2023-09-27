
"""
    (creator::GenotypeCreator)(rng::AbstractRNG, gene_id_counter::Counter, n_pop::Int)

Generate an array of genotype instances based on the provided genotype configuration `creator`. 
The function leverages the specified random number generator `rng` and gene ID counter `gene_id_counter` 
for this purpose. The number of genotypes returned is determined by `n_pop`.

# Returns
- An array of genotype instances, each derived from the given configuration.
"""
function create_genotypes(
    geno_creator::GenotypeCreator, rng::AbstractRNG, gene_id_counter::Counter, n_pop::Int
)::Vector{Genotype}
    [create_genotype(geno_creator, rng, gene_id_counter) for _ in 1:n_pop]
end

"""
    Generic mutation function for `Individual`.

Mutate the genotype of an `Individual` using a given mutation strategy.
"""
function mutate(
    mutator::Mutator,rng::AbstractRNG, gene_id_counter::Counter, indiv::I
) where {I <: Individual}
    geno = mutate(mutator, rng, gene_id_counter, indiv.geno)
    I(indiv.id, geno, indiv.parent_ids)
end

"""
    Batch mutation for a collection of individuals.

Apply a mutation strategy to each individual in the collection `indivs` and return the 
mutated individuals.
"""
function mutate(
    mutator::Mutator, rng::AbstractRNG, gene_id_counter::Counter, indivs::Vector{<:Individual}
)
    [mutate(mutator, rng, gene_id_counter, indiv) for indiv in indivs]
end