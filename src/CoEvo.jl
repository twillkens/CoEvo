module CoEvo

export BasicEcosystem, BasicEcosystemCreator, evolve!,
       Counter, RuntimeReport, RuntimeReporter,
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
       NumbersGameDomain, NumbersGameDomainCreator,
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
using .Ecosystems.Abstract: Reporter
using .Ecosystems.Reporters: RuntimeReport, RuntimeReporter #

println("yo")
using .Ecosystems: Species, Jobs, Archivers

println("yo")
using .Species.Basic: BasicSpecies, BasicSpeciesCreator #
using .Species: Individuals, Evaluators, Reproducers, Reporters

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

using .Evaluators: ScalarFitnessEvaluator, ScalarFitnessEvaluation, Utilities
using .Evaluators.Utilities: NullCriterion, Maximize, Minimize #

using .Reproducers: Replacers, Selectors, Recombiners
using .Replacers: IdentityReplacer, GenerationalReplacer #
using .Selectors: IdentitySelector, FitnessProportionateSelector #
using .Recombiners: CloneRecombiner #
using .Reporters: BasicSpeciesReport, BasicSpeciesReporter #

using .Reporters: Abstract, Metrics
using .Metrics: GenotypeSum, GenotypeSize, EvaluationFitness #
using .Basic: BasicSpecies, BasicSpeciesCreator #

using .Jobs: BasicJob, BasicJobCreator #
using .Jobs: Interactions
using .Interactions: InteractionScheme #
using .Interactions: Domains, MatchMakers, Observers

using .Domains: NumbersGame

using .NumbersGame.Creator: NumbersGameDomain, NumbersGameDomainCreator #
using .NumbersGame.Metrics: Control, Focusing, Gradient, Relativism, Sum #

using .MatchMakers: AllvsAllMatchMaker #

using .Observers.Basic: BasicObserver, BasicObserverCreator #
using .Observers.Metrics: TheVectorWithAverageClosestToPi #

using .Interactions.Reporters.Basic: BasicReporter, BasicReporterCreator #
using .Interactions.Reporters.Metrics: TheTwoVectorsWithGreatestSineOfSums

using .Archivers: DefaultArchiver #

end
