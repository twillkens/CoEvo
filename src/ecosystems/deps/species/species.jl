"""
    Module Species

Provides tools and configurations for defining and managing species in a coevolutionary ecosystem.

# Structure

- **Exported Type**:
    - `BasicSpeciesCreator`: Main configuration type for defining species behavior.
    
- **Dependencies**:
    - Models: Essential foundational components for species.
    - Individuals: Defines the various individual entities within a species.
    - Evaluations: Mechanisms to evaluate the species individuals.
    - Replacers: Defines how species individuals are replaced over evolutionary iterations.
    - Selectors: Mechanisms to select individuals based on certain criteria.
    - Recombiners: Defines the processes of recombination among species individuals.
    - Reporters: Tools for reporting and logging species-related activities.

"""
module Species

export Abstract, Interfaces, Individuals, Evaluators, Reproducers, Reporters, Basic

include("abstract/abstract.jl")
using .Abstract: Abstract

# Dependencies
include("deps/individuals/individuals.jl")
using .Individuals: Individuals

include("deps/evaluators/evaluators.jl")
using .Evaluators: Evaluators

include("deps/reproducers/reproducers.jl")
using .Reproducers: Reproducers

include("deps/reporters/reporters.jl")
using .Reporters: Reporters

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

# Types
include("types/basic.jl")
using .Basic: Basic

end
