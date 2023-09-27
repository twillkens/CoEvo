"""
    Defaults

This module provides default configurations and mutator settings for phenotypes 
in the co-evolutionary ecosystem. It serves as a base for more specific configurations
and mutators that can be defined in other modules.
"""
module Defaults

export DefaultPhenotype, DefaultPhenotypeCreator, DefaultMutator

using ...Individuals.Abstract: PhenotypeCreator, Mutator, Phenotype

struct DefaultPhenotype <: Phenotype end
"""
    DefaultPhenotypeCreator

A default configuration structure for phenotypes in the co-evolutionary ecosystem. 
It acts as a placeholder and can be extended or replaced by more specific configurations.
"""
struct DefaultPhenotypeCreator <: PhenotypeCreator end

"""
    DefaultMutator

A default mutator structure used in the co-evolutionary ecosystem. This basic mutator 
can be extended or replaced with more specific mutation behaviors in derived modules.
"""
struct DefaultMutator <: Mutator end

end
