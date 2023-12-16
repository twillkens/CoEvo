"""
    CoEvo

The `CoEvo` module provides functionality and utilities for co-evolutionary algorithms.

# Main Components:

- `Counters`: Tools and utilities for maintaining and managing counters.
- `Genotypes`: Represents the genetic encoding of an individual.
- `Phenotypes`: Represents the expressed traits or characteristics of an individual.
- `Individuals`: Utilities and functions related to individual organisms.
- `Species`: Functions and structures related to species categorization and management.
- `Criteria`: Defines criteria for evaluation and selection processes.
- `Evaluators`: Tools for evaluating individuals based on specific criteria.
- `Replacers`: Methods to determine which individuals should be replaced in the population.
- `Selectors`: Tools for selecting individuals for reproduction.
- `Recombiners`: Methods for combining genetic information.
- `Mutators`: Functions to introduce genetic mutations.
- `SpeciesCreators`: Utilities for creating new species or subspecies.
- `Metrics`: Tools for measuring various attributes or qualities.
- `Domains`: Represents the domain or environment in which entities exist.
- `Matches`: Represents interactions or competitions between individuals or species.
- `MatchMakers`: Functions to determine potential matches or interactions.
- `Observers`: Monitoring and logging utilities.
- `Results`: Utilities for storing and analyzing results.
- `Environments`: Defines the external conditions or world in which individuals or species interact.
- `Interactions`: Represents direct interactions between individuals or species.
- `Jobs`: Task scheduling and management tools.
- `Performers`: Utilities for performing specific tasks or operations.
- `States`: Represents the state or status of an entity.
- `Reporters`: Reporting and data visualization utilities.
- `Archivers`: Tools for archiving and retrieving data.
- `Ecosystems`: Functions related to broader ecosystems or communities.
- `Names`: Utilities for naming conventions and structures.
- `Configurations`: Configuration management tools including game configurations.

# Notes:
The `Loaders` component, although present in the source, is currently not used or loaded.

# Usage:
See specific sub-modules and functions for detailed usage instructions.
"""
module CoEvo

export Counters, Genotypes, Phenotypes, Individuals, Species, Criteria, Evaluators, Replacers
export Selectors, Recombiners, Mutators, SpeciesCreators, Metrics, Domains, Matches
export MatchMakers, Observers, Results, Environments, Interactions, Jobs, Performers
export States, Reporters, Archivers, Ecosystems, Names, Configurations, run!
export NumbersGameConfiguration
export make_prediction_game_experiment, load_prediction_game_experiment

include("abstract/abstract.jl")
using .Abstract: Abstract

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

include("names/names.jl")
using .Names: Names
println("loaded names")

include("modes/modes.jl")
using .Modes: Modes

include("configurations/configurations.jl")
using .Configurations: Configurations, run!
using .Configurations.NumbersGame: NumbersGame, NumbersGameConfiguration
using .Configurations.PredictionGame: make_prediction_game_experiment, load_prediction_game_experiment
println("loaded configurations")

end
