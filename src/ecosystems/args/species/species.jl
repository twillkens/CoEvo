"""
    SpeciesConfigurations

This module provides tools and configurations for defining and handling species
in a co-evolutionary ecosystem.
"""
module Species

export BasicSpeciesConfiguration

# Exported types and functions

include("utilities/utilities.jl")

include("args/genotypes/genotypes.jl")
include("args/phenotypes/phenotypes.jl")
include("args/individuals/individuals.jl")
include("args/evaluations/evaluations.jl")
include("args/replacers/replacers.jl")
include("args/selectors/selectors.jl")
include("args/recombiners/recombiners.jl")
include("args/mutators/mutators.jl")

include("types/basic/basic.jl")

end
