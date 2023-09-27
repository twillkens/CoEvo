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
export InteractiveDomainConfiguration

include("abstract/abstract.jl")

# Dependencies
include("deps/observers/observers.jl")
include("deps/settings/settings.jl")
include("deps/matchmakers/matchmakers.jl")
include("deps/reporters/reporters.jl")

# Imports
using .Abstract: Problem, MatchMaker, ObservationConfiguration, DomainConfiguration
using ....CoEvo.Abstract: Reporter
using ...Observations: OutcomeObservationConfiguration
using .MatchMakers: MatchMaker, AllvsAllMatchMaker
using .Problems: NumbersGameProblem


function create_domain(domain_creator::InteractiveDomainCreator)
    domain = create_domain(domain_creator.id, domain_creator.setting)
    return domain
end

end