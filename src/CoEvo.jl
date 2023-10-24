module CoEvo

export Counters, Genotypes, Phenotypes, Individuals, Species, Criteria, Evaluators, Replacers
export Selectors, Recombiners, Mutators, SpeciesCreators, Metrics, Domains, Matches
export MatchMakers, Observers, Results, Environments, Interactions, Jobs, Performers
export Measurements, States, Reporters, Archivers, Ecosystems, Loaders, Configurations

include("counters/counters.jl")
using .Counters: Counters
println("loaded counters")

include("genotypes/genotypes.jl")
using .Genotypes: Genotypes
println("loaded genotypes")

include("phenotypes/phenotypes.jl")
using .Phenotypes: Phenotypes
println("loaded phenotypes")

include("individuals/individuals.jl")
using .Individuals: Individuals
println("loaded individuals")

include("species/species.jl")
using .Species: Species
println("loaded species")

include("criteria/criteria.jl")
using .Criteria: Criteria
println("loaded criteria")

include("evaluators/evaluators.jl")
using .Evaluators: Evaluators
println("loaded evaluators")

include("replacers/replacers.jl")
using .Replacers: Replacers
println("loaded replacers")

include("selectors/selectors.jl")
using .Selectors: Selectors
println("loaded selectors")

include("recombiners/recombiners.jl")
using .Recombiners: Recombiners
println("loaded recombiners")

include("mutators/mutators.jl")
using .Mutators: Mutators
println("loaded mutators")

include("species_creators/species_creators.jl")
using .SpeciesCreators: SpeciesCreators
println("loaded species creators")

include("metrics/metrics.jl")
using .Metrics: Metrics
println("loaded metrics")

include("domains/domains.jl")
using .Domains: Domains
println("loaded domains")

include("matches/matches.jl")
using .Matches: Matches
println("loaded matches")

include("matchmakers/matchmakers.jl")
using .MatchMakers: MatchMakers
println("loaded matchmakers")

include("observers/observers.jl")
using .Observers: Observers
println("loaded observers")

include("results/results.jl")
using .Results: Results 
println("loaded results")

include("environments/environments.jl")
using .Environments: Environments
println("loaded environments")

include("interactions/interactions.jl")
using .Interactions: Interactions
println("loaded interactions")

include("jobs/jobs.jl")
using .Jobs: Jobs
println("loaded jobs")

include("performers/performers.jl")
using .Performers: Performers
println("loaded performers")

include("measurements/measurements.jl")
using .Measurements: Measurements
println("loaded measurements")

include("states/states.jl")
using .States: States
println("loaded states")

include("reporters/reporters.jl")
using .Reporters: Reporters
println("loaded reporters")

include("archivers/archivers.jl")
using .Archivers: Archivers
println("loaded archivers")

include("ecosystems/ecosystems.jl")
using .Ecosystems: Ecosystems
println("loaded ecosystems")

include("loaders/loaders.jl")
using .Loaders: Loaders
println("loaded loaders")

include("configurations/configurations.jl")
using .Configurations: Configurations
println("loaded configurations")

end
