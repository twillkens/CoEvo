"""
    Defaults

This module provides default configurations and mutator settings for phenotypes 
in the co-evolutionary ecosystem. It serves as a base for more specific configurations
and mutators that can be defined in other modules.
"""
module Defaults

export DefaultPhenotypeCreator

using ..Abstract: PhenotypeCreator

"""
    DefaultPhenotypeCreator

A default configuration structure for phenotypes in the co-evolutionary ecosystem. 
It acts as a placeholder and can be extended or replaced by more specific configurations.
"""
struct DefaultPhenotypeCreator <: PhenotypeCreator end


end
