module CoEvo

#export BasicEcosystem, BasicEcosystemCreator, evolve!,
#       Counter, RuntimeReporter,
#       BasicSpecies, BasicSpeciesCreator,
#       BasicVectorGenotype, BasicVectorGenotypeCreator,
#       BasicGeneticProgram, BasicGeneticProgramGenotypeCreator,
#       BasicVectorPhenotype, DefaultPhenotype, DefaultPhenotypeCreator,
#       DefaultMutator, BasicGeneticProgramMutator,
#       NullCriterion, Maximize, Minimize,
#       IdentityReplacer, GenerationalReplacer,
#       IdentitySelector, FitnessProportionateSelector,
#       CloneRecombiner, BasicSpeciesReport, BasicSpeciesReporter,
#       GenotypeSum, GenotypeSize, EvaluationFitness,
#       BasicJob, BasicJobCreator, InteractionScheme,
#       NumbersGameEnvironment, NumbersGameEnvironmentCreator,
#       next!, get_outcome_set, refresh!, act,
#       Control, Focusing, Gradient, Relativism, Sum,
#       AllvsAllMatchMaker,
#       BasicObserver, BasicObserverCreator,
#       TheVectorWithAverageClosestToPi,
#       BasicReporter, BasicReporterCreator,
#       TheTwoVectorsWithGreatestSineOfSums,
#       DefaultArchiver, BasicIndividual, BasicIndividualCreator,
#       NumbersGameEnvironmentCreator

include("ecosystems/ecosystems.jl")

using .Ecosystems.Basic: BasicEcosystem, BasicEcosystemCreator, evolve! #
println("using .Ecosystems.Basic: BasicEcosystem, BasicEcosystemCreator, evolve!")
using .Ecosystems.Utilities.Counters: Counter #
println("using .Ecosystems.Utilities.Counters: Counter")
using .Ecosystems.Reporters.Abstract: Reporter
println("using .Ecosystems.Reporters.Abstract: Reporter")

using .Ecosystems: Species, Metrics, Interactions, Jobs, Performers, Measures, Reporters, Archivers
println("using .Ecosystems: Species, Metrics, Interactions, Jobs, Performers, Measures, Reporters, Archivers")

using .Species.Basic: BasicSpecies, BasicSpeciesCreator #
println("using .Species.Basic: BasicSpecies, BasicSpeciesCreator")
using .Species: Genotypes, Phenotypes, Individuals, Evaluators
println("using .Species: Genotypes, Phenotypes, Individuals, Evaluators")
using .Species: Replacers, Selectors, Recombiners, Mutators, Interfaces
println("using .Species: Replacers, Selectors, Recombiners, Mutators, Interfaces")

using .Individuals: Individual

using .Genotypes.Vectors.Basic: BasicVectorGenotype, BasicVectorGenotypeCreator  #
using .Genotypes.GeneticPrograms: GeneticProgramGenotype
using .Genotypes.GeneticPrograms: GeneticProgramGenotypeCreator #

using .Phenotypes.Defaults: DefaultPhenotypeCreator #
using .Phenotypes.Vectors.Basic: BasicVectorPhenotype

using .Mutators.Identity: IdentityMutator #
using .Mutators.GeneticPrograms: GeneticProgramMutator #

using .Evaluators.Types: ScalarFitnessEvaluator, ScalarFitnessEvaluation
println("using .Evaluators.Types: ScalarFitnessEvaluator, ScalarFitnessEvaluation")

using .Replacers.Types: IdentityReplacer, GenerationalReplacer #
println("using .Replacers.Types: IdentityReplacer, GenerationalReplacer")
using .Selectors.Types: IdentitySelector, FitnessProportionateSelector #
println("using .Selectors.Types: IdentitySelector, FitnessProportionateSelector")
using .Recombiners.Types: CloneRecombiner #
println("using .Recombiners.Types: CloneRecombiner")

using .Reporters.Basic: BasicReporter, BasicReport #
using .Reporters.Runtime: RuntimeReporter, RuntimeReport #

#using .Metrics.Species.Genotype.Types: GenotypeSumMetric, GenotypeSizeMetric # 
#using .Metrics.Species.Evaluation.Types: EvaluationFitnessMetric # 
#using .Metrics.Interaction.Types: EpisodeLengthMetric

using .Jobs.Basic: BasicJob, BasicJobCreator #

using .Interactions: Domains, MatchMakers, Observers, Results, Environments
using .Interactions.Types: BasicInteraction #

using .Domains.Types.NumbersGame: NumbersGameDomain #
using .Metrics.Outcome.Types.NumbersGame: Control, Focusing, Gradient, Relativism, Sum #

using .MatchMakers.AllvsAll: AllvsAllMatchMaker #

using .Observers.Basic: BasicObserver

using .Archivers.Default: DefaultArchiver #

end
