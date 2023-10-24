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
export Basic

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("basic/basic.jl")
using .Basic: Basic

end