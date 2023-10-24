module Identity

export IdentityMutator

import ...Mutators.Interfaces: mutate

using Random: AbstractRNG
using ...Counters: Counter
using ...Genotypes.Abstract: Genotype
using ..Mutators.Abstract: Mutator

struct IdentityMutator <: Mutator end

function mutate(::IdentityMutator, ::AbstractRNG, ::Counter, genotype::Genotype) 
    return deepcopy(genotype)
end

end