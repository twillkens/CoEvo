module Identity

export IdentityMutator

import ....Interfaces: mutate

using Random: AbstractRNG
using ....Abstract

struct IdentityMutator <: Mutator end

function mutate(::IdentityMutator, ::AbstractRNG, ::Counter, genotype::Genotype) 
    return deepcopy(genotype)
end

end