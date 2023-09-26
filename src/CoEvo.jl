"""
    CoEvo

A module that encapsulates functionality related to the coevolutionary ecosystem.
This module provides tools and interfaces to handle evolutionary algorithms,
interactions, species, and various other components of a coevolutionary system.

# Exports
- `evolve!`: Function to trigger the evolution of an ecosystem.
- Reporters (`Reporter`, `RuntimeReporter`, `CohortMetricReporter`): Interfaces and implementations for reporting results and statistics.
- Counters and Metrics (`Counter`, `GenotypeSum`, `GenotypeSize`, `EvaluationFitness`): Tools for tracking and measuring certain properties during evolution.
- Configurations: Set of structures defining behavior and properties for various components (`CoevolutionaryEcosystemConfiguration`, `BasicSpeciesConfiguration`, `VectorGenotypeConfiguration`, etc.).
- Utilities: Helpers and utilities to facilitate various functionalities (`DefaultPhenotypeConfiguration`, `DefaultMutator`, etc.).
- Ecosystem Elements (`AsexualIndividualConfiguration`, `SexualIndividualConfiguration`, `ScalarFitnessEvaluationConfiguration`, etc.): Configurations and definitions to handle species, individuals, evaluations, and more.
- Jobs (`InteractionJobConfiguration`, `InteractiveDomainConfiguration`, `AllvsAllMatchMaker`, `NumbersGame`): Define and handle interaction jobs between species.
- Archivers (`DefaultArchiver`): For storing historical data.
- Others: Various functionalities and configurations to provide rich coevolutionary behavior (`CloneRecombiner`, `GenerationalReplacer`, `IdentitySelector`, etc.).

The module structures its content based on the different elements of a coevolutionary ecosystem and provides extensive configuration options to customize and experiment with different behaviors and properties.

# Internals
Files and directories included:
- `abstract/abstract.jl`: Contains abstract type definitions.
- `utilities/utilities.jl`: Provides various utility functions.
- `ecosystems/ecosystems.jl`: Core functionalities related to ecosystems.
... and more.

# Notes
Remember to keep the implementations updated with the module's structure and hierarchy. 
The configurations provided are extensive and allow rich customization; ensure you're using 
the right one for your needs.
"""
module CoEvo

# Exports
export evolve!,
       Reporter, Counter, RuntimeReporter, CohortMetricReporter,
       GenotypeSum, GenotypeSize, EvaluationFitness,
       CoevolutionaryEcosystemConfiguration, BasicSpeciesConfiguration,
       VectorGenotypeConfiguration, DefaultPhenotypeConfiguration,
       AsexualIndividualConfiguration, SexualIndividualConfiguration,
       ScalarFitnessEvaluationConfiguration, IdentityReplacer,
       GenerationalReplacer, IdentitySelector, FitnessProportionateSelector,
       CloneRecombiner, DefaultMutator, SizeGenotypeReporter, 
       SumGenotypeReporter, FitnessEvaluationReporter,
       InteractionJobConfiguration, InteractiveDomainConfiguration,
       AllvsAllMatchMaker, NumbersGame, OutcomeObservationConfiguration,
       DefaultArchiver, BasicGeneticProgramGenotypeConfiguration,
       BasicVectorGenotypeConfiguration

# File includes
include("abstract/abstract.jl")
include("utilities/utilities.jl")
include("ecosystems/ecosystems.jl")

# Usings (arranged by source directory)
using .Abstract: Reporter

using .Utilities.Counters: Counter
using .Utilities.Metrics: GenotypeSum, GenotypeSize, EvaluationFitness

using .Ecosystems: CoevolutionaryEcosystemConfiguration, evolve!
using .Ecosystems.Observations: OutcomeObservationConfiguration
using .Ecosystems.Species: BasicSpeciesConfiguration
using .Ecosystems.Species.Substrates.Defaults: DefaultPhenotypeConfiguration
using .Ecosystems.Species.Substrates.Defaults: DefaultMutator
using .Ecosystems.Species.Substrates.Vectors: BasicVectorGenotypeConfiguration
using .Ecosystems.Species.Substrates.GeneticPrograms.Genotypes: BasicGeneticProgramGenotypeConfiguration
using .Ecosystems.Species.Individuals: AsexualIndividualConfiguration, 
                                     SexualIndividualConfiguration
using .Ecosystems.Species.Evaluations: ScalarFitnessEvaluationConfiguration
using .Ecosystems.Species.Replacers: IdentityReplacer, GenerationalReplacer
using .Ecosystems.Species.Selectors: IdentitySelector, FitnessProportionateSelector
using .Ecosystems.Species.Recombiners: CloneRecombiner
using .Ecosystems.Species.Reporters: CohortMetricReporter
using .Ecosystems.Jobs: InteractionJobConfiguration
using .Ecosystems.Jobs.Domains: InteractiveDomainConfiguration
using .Ecosystems.Jobs.Domains.MatchMakers: AllvsAllMatchMaker
using .Ecosystems.Jobs.Domains.Problems.NumbersGame: NumbersGame
using .Ecosystems.Archivers: DefaultArchiver
using .Ecosystems.Reporters: RuntimeReporter

end
