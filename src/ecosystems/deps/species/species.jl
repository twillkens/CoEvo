"""
    SpeciesConfigurations

This module provides tools and configurations for defining and handling species
in a co-evolutionary ecosystem.
"""
module Species

export BasicSpeciesConfiguration

# Exported types and functions

include("utilities/utilities.jl")

include("deps/genotypes/genotypes.jl")
include("deps/phenotypes/phenotypes.jl")
include("deps/individuals/individuals.jl")
include("deps/evaluations/evaluations.jl")
include("deps/replacers/replacers.jl")
include("deps/selectors/selectors.jl")
include("deps/recombiners/recombiners.jl")
include("deps/mutators/mutators.jl")
include("deps/reporters/reporters.jl")

include("types/basic/basic.jl")

end
