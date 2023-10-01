module CoEvo

export BasicEcosystem, BasicEcosystemCreator, evolve!,
       Counter, RuntimeReporter,
       BasicSpecies, BasicSpeciesCreator,
       BasicVectorGenotype, BasicVectorGenotypeCreator,
       BasicGeneticProgram, BasicGeneticProgramGenotypeCreator,
       BasicVectorPhenotype, DefaultPhenotype, DefaultPhenotypeCreator,
       DefaultMutator, BasicGeneticProgramMutator,
       NullCriterion, Maximize, Minimize,
       IdentityReplacer, GenerationalReplacer,
       IdentitySelector, FitnessProportionateSelector,
       CloneRecombiner, BasicSpeciesReport, BasicSpeciesReporter,
       GenotypeSum, GenotypeSize, EvaluationFitness,
       BasicJob, BasicJobCreator, InteractionScheme,
       NumbersGameEnvironment, NumbersGameEnvironmentCreator,
       next!, get_outcome_set, refresh!, act,
       Control, Focusing, Gradient, Relativism, Sum,
       AllvsAllMatchMaker,
       BasicObserver, BasicObserverCreator,
       TheVectorWithAverageClosestToPi,
       BasicReporter, BasicReporterCreator,
       TheTwoVectorsWithGreatestSineOfSums,
       DefaultArchiver, BasicIndividual, BasicIndividualCreator,
       NumbersGameEnvironmentCreator

include("ecosystems/ecosystems.jl")

using .Ecosystems.Basic: BasicEcosystem, BasicEcosystemCreator, evolve! #
using .Ecosystems.Utilities.Counters: Counter #
using .Ecosystems.Reporters.Abstract: Reporter

println("yo")
using .Ecosystems: Species, Metrics, Interactions, Jobs, Performers, Measures, Reporters, Archivers

println("yo")
using .Species.Basic: BasicSpecies, BasicSpeciesCreator #
using .Species: Individuals, Evaluators, Reproducers

using .Individuals.Basic: BasicIndividual, BasicIndividualCreator #
using .Individuals: Genotypes, Phenotypes, Mutators

using .Genotypes.Vectors.Basic: BasicVectorGenotype, BasicVectorGenotypeCreator  #
using .Genotypes.GeneticPrograms.Basic: BasicGeneticProgramGenotype
using .Genotypes.GeneticPrograms.Basic: BasicGeneticProgramGenotypeCreator #

println("yo")
using .Phenotypes.Defaults: DefaultPhenotypeCreator #
using .Phenotypes.Vectors.Basic: BasicVectorPhenotype

println("yo")
using .Mutators.Defaults: DefaultMutator #
println("yo")
using .Mutators.GeneticPrograms.Basic: BasicGeneticProgramMutator #
println("yo")

using .Evaluators.Types: ScalarFitnessEvaluator, ScalarFitnessEvaluation
using .Evaluators.Criteria.Types: NullCriterion, Maximize, Minimize #

using .Reproducers: Replacers, Selectors, Recombiners
using .Replacers.Types: IdentityReplacer, GenerationalReplacer #
using .Selectors.Types: IdentitySelector, FitnessProportionateSelector #
using .Recombiners.Types: CloneRecombiner #

using .Reporters.Species.Basic: BasicSpeciesReport, BasicSpeciesReporter #
using .Reporters.Ecosystem.Runtime: RuntimeReporter #

using .Metrics.Species.Genotype.Types: GenotypeSumMetric, GenotypeSizeMetric # 
using .Metrics.Species.Evaluation.Types: EvaluationFitnessMetric # 
using .Metrics.Interaction.Types: EpisodeLengthMetric

using .Jobs.Basic: BasicJob, BasicJobCreator #

using .Interactions.Basic: BasicInteraction #
using .Interactions: Environments, MatchMakers, Observers

using .Environments: NumbersGame

using .NumbersGame.Environment: NumbersGameEnvironment, NumbersGameEnvironmentCreator #
using .NumbersGame.Metrics: Sum, Control, Focusing, Gradient, Relativism #

using .MatchMakers.AllvsAll: AllvsAllMatchMaker #

using .Observers.Basic: BasicObserver

using .Archivers.Default: DefaultArchiver #

end
