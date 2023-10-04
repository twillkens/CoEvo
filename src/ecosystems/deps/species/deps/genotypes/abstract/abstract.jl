module Abstract

export Gene, Genotype, GenotypeCreator, AbstractRNG

using Random: AbstractRNG
using .....Ecosystems.Utilities.Counters: Counter

abstract type Gene end

abstract type Genotype end

abstract type GenotypeCreator end


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

end