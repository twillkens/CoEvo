"""
    Module Species

Provides tools and configurations for defining and managing species in a coevolutionary ecosystem.

# Structure

- **Exported Type**:
    - `BasicSpeciesConfiguration`: Main configuration type for defining species behavior.
    
- **Dependencies**:
    - Substrates: Essential foundational components for species.
    - Individuals: Defines the various individual entities within a species.
    - Evaluations: Mechanisms to evaluate the species individuals.
    - Replacers: Defines how species individuals are replaced over evolutionary iterations.
    - Selectors: Mechanisms to select individuals based on certain criteria.
    - Recombiners: Defines the processes of recombination among species individuals.
    - Reporters: Tools for reporting and logging species-related activities.

"""
module Species

export BasicSpeciesConfiguration

# Dependencies
include("deps/substrates/substrates.jl")
include("deps/individuals/individuals.jl")
include("deps/evaluations/evaluations.jl")
include("deps/replacers/replacers.jl")
include("deps/selectors/selectors.jl")
include("deps/recombiners/recombiners.jl")
include("deps/reporters/reporters.jl")

# Types
include("types/basic.jl")

end
