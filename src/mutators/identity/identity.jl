module Identity

export IdentityMutator

import ..Mutators: mutate

using Random: AbstractRNG
using ...Counters: Counter
using ...Genotypes: Genotype
using ..Abstract

struct IdentityMutator <: Mutator end

function mutate(::IdentityMutator, ::AbstractRNG, ::Counter, genotype::Genotype) 
    return deepcopy(genotype)
end

end