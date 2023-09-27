"""
    Abstract

This module contains abstract definitions related to genotype configurations in the co-evolutionary ecosystem.
It provides foundational behaviors for genotype configurations, which can be extended in derived modules.
"""
module Abstract

export Genotype, GenotypeCreator, Mutator, Phenotype, PhenotypeCreator
export Individual, IndividualCreator, create_genotype, mutate
export create_individual, create_phenotype

using Random: AbstractRNG
using ....Ecosystems.Utilities.Counters: Counter

abstract type Individual end

abstract type IndividualCreator end

abstract type Genotype end

abstract type GenotypeCreator end

abstract type Mutator end

abstract type Phenotype end

abstract type PhenotypeCreator end


"""
    (geno_creator::GenotypeCreator)(rng::AbstractRNG, counter::Counter)

Attempt to generate a genotype instance based on the provided genotype configuration `geno_creator`, 
utilizing the given random number generator `rng` and gene ID counter `counter`.

# Exceptions
- Raises an `ErrorException` if the specific genotype configuration hasn't been implemented.
"""
function create_genotype(geno_creator::GenotypeCreator, ::AbstractRNG, ::Counter)::Genotype
    throw(ErrorException("Default genotype creation for $geno_creator not implemented."))
end

function create_phenotype(pheno_creator::PhenotypeCreator, geno::Genotype)::Phenotype
    throw(ErrorException("Default phenotype creation for $pheno_creator and $geno not implemented."))
end

function create_individual(
    indiv_creator::IndividualCreator, 
    ::Int, 
    geno::Genotype, 
    parent_ids::Vector{Int}
)::Individual
    throw(ErrorException("Default individual creation for $indiv_creator, $geno, not implemented."))
end
"""
    Generic mutation function for `Individual`.

Mutate the genotype of an `Individual` using a given mutation strategy.
"""
function mutate(
    ::Mutator, ::AbstractRNG, ::Counter, geno::Genotype
)::Genotype
    throw(ErrorException("Default mutation for genotype $geno not implemented."))
end


end
