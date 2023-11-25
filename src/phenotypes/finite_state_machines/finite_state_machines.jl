module FiniteStateMachines

export FiniteStateMachinePhenotype

import ..Phenotypes: create_phenotype, act!

using ...Genotypes.FiniteStateMachines: FiniteStateMachineGenotype
using ..Phenotypes: Phenotype, PhenotypeCreator

struct FiniteStateMachinePhenotype{T} <: Phenotype
    id::Int
    start::Tuple{T, Bool}
    links::Dict{Tuple{T, Bool}, Tuple{T, Bool}}
end

function FiniteStateMachinePhenotype(
    start::Tuple{T, Bool}, links::Dict{Tuple{T, Bool}, Tuple{T, Bool}}
) where T
    FiniteStateMachinePhenotype(0, start, links)
end

function create_phenotype(::PhenotypeCreator, genotype::FiniteStateMachineGenotype, id::Int)
    new_links = Dict(
        ((source, bit) => (target, target in genotype.ones))
        for ((source, bit), target) in genotype.links
    )
    start_tuple = (genotype.start, genotype.start in genotype.ones)
    phenotype = FiniteStateMachinePhenotype(id, start_tuple, new_links)
    return phenotype
end

function act!(phenotype::FiniteStateMachinePhenotype{T}, state::T, bit::Bool) where T
    next_state, next_bit = phenotype.links[(state, bit)]
    return next_state, next_bit
end

end