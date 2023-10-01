"""
    Interactions

The `Interactions` module provides structures and functionality associated with 
interactive interactions. It brings together problems, matchmakers, observation configurations,
and reporters to facilitate interactive interaction configuration.

# Structures
- `InteractiveDomainConfiguration`: Represents the configuration of an interactive interaction.

# Dependencies
- `Problems`: Contains different types of problems that the interaction can work with.
- `MatchMakers`: Provides mechanisms for creating matchings in the interaction.
- `Reporters`: Allows for reporting and logging activities within the interaction.
"""
module Interactions

# Exported Structures
export Abstract, Environments, MatchMakers, Observers
export Basic

include("abstract/abstract.jl")
using .Abstract: Abstract
# Dependencies
include("deps/environments/environments.jl")
using .Environments: Environments

include("deps/matchmakers/matchmakers.jl")
using .MatchMakers: MatchMakers

include("deps/observers/observers.jl")
using .Observers: Observers

include("types/types.jl")
using .Types: Types

end