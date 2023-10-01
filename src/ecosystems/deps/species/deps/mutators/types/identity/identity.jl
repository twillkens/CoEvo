module Identity

export IdentityMutator

using ...Mutators.Abstract: Mutator
using Random: AbstractRNG
using .....Ecosystems.Utilities.Counters: Counter
using  ....Species.Genotypes.Abstract: Genotype

import ...Mutators.Interfaces: mutate

struct IdentityMutator <: Mutator end

function mutate(::IdentityMutator, ::AbstractRNG, ::Counter, geno::Genotype) 
    return geno
end
"""
    DefaultMutator

A default mutator structure used in the co-evolutionary ecosystem. This basic mutator 
can be extended or replaced with more specific mutation behaviors in derived modules.
"""

end