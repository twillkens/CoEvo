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
       create_domain, next!, get_outcome_set, refresh!, act,
       Control, Focusing, Gradient, Relativism, Sum,
       AllvsAllMatchMaker,
       BasicObserver, BasicObserverCreator,
       TheVectorWithAverageClosestToPi,
       BasicReporter, BasicReporterCreator,
       TheTwoVectorsWithGreatestSineOfSums,
       DefaultArchiver, BasicIndividual, BasicIndividualCreator

include("ecosystems/ecosystems.jl")

using .Ecosystems.Basic: BasicEcosystem, BasicEcosystemCreator, evolve! #
using .Ecosystems.Utilities.Counters: Counter #
using .Ecosystems.Reporters.Abstract: Reporter

println("yo")
using .Ecosystems: Species, Metrics, Domains, Jobs, Performers, Measures, Reporters, Archivers

println("yo")
using .Species.Basic: BasicSpecies, BasicSpeciesCreator #
using .Species: Individuals, Evaluators, Reproducers

println("yo")
using .Individuals.Basic: BasicIndividual, BasicIndividualCreator #
using .Individuals: Genotypes, Phenotypes, Mutators

println("yo")
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
using .Replacers: IdentityReplacer, GenerationalReplacer #
using .Selectors: IdentitySelector, FitnessProportionateSelector #
using .Recombiners: CloneRecombiner #

using .Reporters.Species.Basic: BasicSpeciesReport, BasicSpeciesReporter #
using .Reporters.Ecosystem.Runtime: RuntimeReporter #

using .Metrics.Species.Genotype.Types: GenotypeSumMetric, GenotypeSizeMetric # 
using .Metrics.Species.Evaluation.Types: EvaluationFitnessMetric # 
using .Metrics.Domain.Types: EpisodeLengthMetric

using .Jobs.Basic: BasicJob, BasicJobCreator #

using .Domains.Basic: BasicDomain #
using .Domains: Environments, MatchMakers, Observers

using .Environments: NumbersGame

using .NumbersGame.Environment: NumbersGameEnvironment
using .NumbersGame.Metrics: Sum, Control, Focusing, Gradient, Relativism #

using .MatchMakers.AllvsAll: AllvsAllMatchMaker #

using .Observers.Basic: BasicObserver

using .Archivers.Default: DefaultArchiver #

end
