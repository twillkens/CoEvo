"""
    Domains

The `Domains` module provides structures and functionality associated with 
interactive domains. It brings together problems, matchmakers, observation configurations,
and reporters to facilitate interactive domain configuration.

# Structures
- `InteractiveDomainConfiguration`: Represents the configuration of an interactive domain.

# Dependencies
- `Problems`: Contains different types of problems that the domain can work with.
- `MatchMakers`: Provides mechanisms for creating matchings in the domain.
- `Reporters`: Allows for reporting and logging activities within the domain.
"""
module Domains

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

include("types/basic.jl")
using .Basic: Basic

end