module FiniteStateMachines

export FiniteStateMachinePhenotype

import ..Phenotypes: create_phenotype, act!

using ...Genotypes.FiniteStateMachines: FiniteStateMachineGenotype
using ..Phenotypes: Phenotype, PhenotypeCreator

struct FiniteStateMachinePhenotype{T} <: Phenotype
    start::Tuple{T, Bool}
    links::Dict{Tuple{T, Bool}, Tuple{T, Bool}}
end

function create_phenotype(::PhenotypeCreator, genotype::FiniteStateMachineGenotype)
    new_links = Dict(
        ((source, bit) => (target, target in genotype.ones))
        for ((source, bit), target) in genotype.links
    )
    phenotype = FiniteStateMachinePhenotype(
        (genotype.start, genotype.start in genotype.ones),
        new_links
    )
    return phenotype
end

function act!(phenotype::FiniteStateMachinePhenotype{T}, state::T, bit::Bool) where T
    next_state, next_bit = phenotype.links[(state, bit)]
    return next_state, next_bit
end

end