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
module Topologies

# Exported Structures
export Domains, MatchMakers, Observers, Reporters
export Basic

# Dependencies
include("deps/domains/domains.jl")
using .Domains: Domains

include("deps/matchmakers/matchmakers.jl")
using .MatchMakers: MatchMakers

include("deps/observers/observers.jl")
using .Observers: Observers

include("deps/reporters/reporters.jl")
using .Reporters: Reporters

include("types/basic.jl")
using .Basic: Basic

end