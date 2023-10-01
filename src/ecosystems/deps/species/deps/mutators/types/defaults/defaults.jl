module Defaults

export DefaultMutator

using ..Abstract: Mutator, AbstractRNG, Genotype
using .....Ecosystems.Utilities.Counters: Counter

import ..Interfaces: mutate, Genotype
import ..Abstract: Genotype

struct DefaultMutator <: Mutator end

function mutate(::DefaultMutator, ::AbstractRNG, ::Counter, geno::Genotype) 
    return geno
end
"""
    DefaultMutator

A default mutator structure used in the co-evolutionary ecosystem. This basic mutator 
can be extended or replaced with more specific mutation behaviors in derived modules.
"""

end