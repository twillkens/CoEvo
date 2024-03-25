export DCTRuleCreator, DCTInitialConditionCreator, create_genotypes

import ....Interfaces: create_genotypes
using Random
using ....Abstract
using ...Genotypes.Vectors: BasicVectorGenotype

Base.@kwdef struct DCTRuleCreator <: GenotypeCreator
    length::Int = 128
end

function create_genotypes(
    genotype_creator::DCTRuleCreator, n_population::Int, state::State   
)
    genotypes = BasicVectorGenotype{Int}[]
    for _ in 1:n_population
        genes = rand(state.rng, 0:1, genotype_creator.length)
        genotype = BasicVectorGenotype(genes)
        push!(genotypes, genotype)
    end
    return genotypes
end

Base.@kwdef struct DCTInitialConditionCreator <: GenotypeCreator
    length::Int = 149
end

function create_genotypes(
    genotype_creator::DCTInitialConditionCreator, n_population::Int, state::State   
)
    genotypes = BasicVectorGenotype{Int}[]
    for _ in 1:n_population
        n_zeros = rand(state.rng, 0:genotype_creator.length)
        genes = [zeros(Int, n_zeros) ; ones(Int, genotype_creator.length - n_zeros)]
        shuffle!(state.rng, genes)
        genotype = BasicVectorGenotype(genes)
        push!(genotypes, genotype)
    end

    return genotypes
end
