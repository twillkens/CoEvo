"""
    CoEvo

A module encapsulating the functionality related to the coevolutionary ecosystem.
This module provides tools and interfaces to handle evolutionary algorithms,
interactions, species, and various other components of a coevolutionary system.

## Exports

### Core Functionalities
- `evolve!`: Function to trigger the evolution of an ecosystem.

### Reporting Tools
- `Reporter`, `RuntimeReporter`, `CohortMetricReporter`

### Counters and Metrics
- `Counter`, `GenotypeSum`, `GenotypeSize`, `EvaluationFitness`

### Creators
- `BasicEcosystemCreator`, `BasicSpeciesCreator`,
  `VectorGenotypeCreator`, `DefaultPhenotypeCreator`, 
  `ScalarFitnessEvaluator`, `InteractionJobCreator`, 
  `InteractionScheme`, `OutcomeObservationCreator`, 
  `BasicGeneticProgramGenotypeCreator`, `BasicVectorGenotypeCreator`

### Utilities and Ecosystem Elements
- `IdentityReplacer`, `GenerationalReplacer`, `IdentitySelector`,
  `FitnessProportionateSelector`, `CloneRecombiner`, `DefaultMutator`

### Jobs and Domains
- `AllvsAllMatchMaker`, `NumbersGame`

### Archivers
- `DefaultArchiver`

## Internals
Files and directories included:
- `abstract/abstract.jl`: Contains abstract type definitions.
- `utilities/utilities.jl`: Provides utility functions.
- `ecosystems/ecosystems.jl`: Core functionalities related to ecosystems.
... and more.

## Notes
Remember to keep the implementations updated with the module's structure and hierarchy. 
Creators are extensive, allowing rich customization; ensure the correct one is used.

"""
module CoEvo

# Exports
export evolve!,
       # Reporting Tools
       Reporter, RuntimeReporter, CohortMetricReporter,
       # Counters and Metrics
       Counter, GenotypeSum, GenotypeSize, EvaluationFitness,
       # Creators
       BasicEcosystemCreator, BasicSpeciesCreator,
       VectorGenotypeCreator, DefaultPhenotypeCreator,
       ScalarFitnessEvaluator, InteractionJobCreator,
       InteractionScheme, OutcomeObservationCreator,
       BasicGeneticProgramGenotypeCreator, BasicVectorGenotypeCreator,
       # Utilities and Ecosystem Elements
       IdentityReplacer, GenerationalReplacer, IdentitySelector,
       FitnessProportionateSelector, CloneRecombiner, DefaultMutator,
       # Jobs and Domains
       AllvsAllMatchMaker, NumbersGame,
       # Archivers
       DefaultArchiver

# File includes
# include("abstract/abstract.jl")
#include("utilities/utilities.jl")
include("ecosystems/ecosystems.jl")

# # Usings (arranged by source directory)
# using .Abstract: Reporter
# 
# using .Utilities.Counters: Counter
# using .Utilities.Criteria: Maximize, Minimize, NullCriterion
# using .Utilities.Metrics: GenotypeSum, GenotypeSize, EvaluationFitness
# 
# using .Ecosystems: Observations, BasicEcosystemCreator, evolve!
# using .Observations: OutcomeObservationCreator
# using .Ecosystems.Species: Species, BasicSpeciesCreator
# using .Species.Individuals: Individuals, BasicIndividualCreator
# 
# using .Individuals: Models
# using .Models.Defaults: DefaultPhenotype, DefaultPhenotypeCreator, DefaultMutator
# using .Models.Vectors: BasicVectorGenotypeCreator
# using .Models.GeneticPrograms: GeneticPrograms, ExpressionNodeGene 
# using .GeneticPrograms: GraphGeneticProgramPhenotype, BasicGeneticProgramMutator
# using .Models.Evaluations: ScalarFitnessEvaluator
# 
# using .Species.Reproducers: Reproducers, Replacers, Selectors, Recombiners
# using .Replacers: IdentityReplacer, GenerationalReplacer
# using .Selectors: IdentitySelector, FitnessProportionateSelector
# using .Species.Recombiners: CloneRecombiner
# using .Species.Reporters: CohortMetricReport, CohortMetricReporter
# using .Ecosystems.Jobs: Jobs, InteractionJobCreator
# using .Jobs.Domains: Domains, InteractionScheme
# using .Domains.MatchMakers: MatchMakers, AllvsAllMatchMaker
# using .Domains.Problems: Problems
# using .Domains.Problems.NumbersGame: NumbersGame, Control, Sum, Gradient, Focusing, Relativism
# using .Ecosystems.Archivers: DefaultArchiver
# using .Ecosystems.Reporters: RuntimeReport, RuntimeReporter

end
