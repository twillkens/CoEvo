module CoEvo

export Ecosystem, EcosystemCreator,
       BasicEcosystem, BasicEcosystemCreator, evolve!,
       Counter,
       Species,
       AbstractSpecies,
       create_species,
       BasicSpecies, BasicSpeciesCreator,
       Genotypes,
       Genotype,
       create_genotype,
       VectorGenotype, VectorGenotypeCreator,
       BasicVectorGenotype, BasicVectorGenotypeCreator,
       GeneticProgramGenotype, GeneticProgramGenotypeCreator,
       Phenotypes,
       Phenotype, PhenotypeCreator,
       create_phenotype, act,
       DefaultPhenotypeCreator,
       BasicVectorPhenotype,
       Individuals,
       Individual,
       Evaluators,
       create_evaluation, get_ranked_ids,
       Evaluation, Evaluator,
       ScalarFitnessEvaluator, ScalarFitnessEvaluation,
       Replacers,
       Replacer,
       replace,
       IdentityReplacer, GenerationalReplacer,
       Selectors,
       Selector,
       select,
       IdentitySelector, FitnessProportionateSelector,
       Recombiners,
       Recombiner,
       recombine,
       CloneRecombiner,
       Mutators,
       Mutator,
       mutate,
       IdentityMutator, GeneticProgramMutator, NoiseInjectionMutator,
       Metrics,
       Metric,
       OutcomeMetric,
       NumbersGameMetrics,
       ObservationMetric,
       SpeciesMetric,
       InteractionMetric,
       EvaluationMetric,
       TestBasedFitness, AllSpeciesFitness,
       Interactions,
       Interaction,
       interact,
       Domains, MatchMakers, Observers, Results, Environments,
       BasicInteraction,
       Domain,
       NumbersGameDomain,
       MatchMaker,
       AllvsAllMatchMaker,
       Observer, Observation,
       create_observation,
       BasicObserver, BasicObservation, NullObservation,
       Result,
       Environment, EnvironmentCreator,
       create_environment, next!, get_outcome_set, is_active, observe!,
       StatelessEnvironment, StatelessEnvironmentCreator,
       Jobs,
       Job, JobCreator,
       create_jobs,
       BasicJob, BasicJobCreator,
       Performers,
       Performer,
       perform,
       BasicPerformer,
       Measurements,
       Measurement,
       BasicStatisticalMeasurement,
       Reporters,
       Reporter,
       create_report, measure,
       BasicReporter, BasicReport,
       RuntimeReporter, RuntimeReport,
       Archivers,
       Archiver,
       archive!,
       BasicArchiver


include("ecosystems/ecosystems.jl")

using .Ecosystems.Abstract: Ecosystem, EcosystemCreator
using .Ecosystems.Basic: BasicEcosystem, BasicEcosystemCreator, evolve! 
using .Ecosystems.Utilities.Counters: Counter
println("loaded ecosystems")

using .Ecosystems: Species
using .Species.Abstract: AbstractSpecies
using .Species.Interfaces: create_species
using .Species.Basic: BasicSpecies, BasicSpeciesCreator 
println("loaded species")

using .Species: Genotypes
using .Genotypes.Abstract: Genotype
using .Genotypes.Interfaces: create_genotype
using .Genotypes.Vectors.Abstract: VectorGenotype, VectorGenotypeCreator
using .Genotypes.Vectors.Basic: BasicVectorGenotype, BasicVectorGenotypeCreator  
using .Genotypes.GeneticPrograms: GeneticProgramGenotype
using .Genotypes.GeneticPrograms: GeneticProgramGenotypeCreator 
println("loaded genotypes")

using .Species: Phenotypes
using .Phenotypes.Abstract: Phenotype, PhenotypeCreator
using .Phenotypes.Interfaces: create_phenotype, act
using .Phenotypes.Defaults: DefaultPhenotypeCreator 
using .Phenotypes.Vectors.Basic: BasicVectorPhenotype
println("loaded phenotypes")

using .Species: Individuals
using .Individuals: Individual
println("loaded individuals")

using .Species: Mutators
using .Mutators.Abstract: Mutator
using .Mutators.Interfaces: mutate
using .Mutators.Types.Identity: IdentityMutator 
using .Mutators.Types.GeneticPrograms: GeneticProgramMutator 
using .Mutators.Types.NoiseInjection: NoiseInjectionMutator 
println("loaded mutators")

using .Species: Evaluators
using .Evaluators.Interfaces: create_evaluation, get_ranked_ids
using .Evaluators.Abstract: Evaluation, Evaluator
using .Evaluators.Types.ScalarFitness: ScalarFitnessEvaluator, ScalarFitnessEvaluation
using .Evaluators.Types.Null: NullEvaluator, NullEvaluation
println("loaded evaluators")

using .Species: Replacers
using .Replacers.Abstract: Replacer
using .Replacers.Interfaces: replace
using .Replacers.Types: IdentityReplacer, GenerationalReplacer 
println("loaded replacers")

using .Species: Selectors
using .Selectors.Abstract: Selector
using .Selectors.Interfaces: select
using .Selectors.Types: IdentitySelector, FitnessProportionateSelector 
println("loaded selectors")

using .Species: Recombiners
using .Recombiners.Abstract: Recombiner
using .Recombiners.Interfaces: recombine
using .Recombiners.Types: CloneRecombiner 
println("loaded recombiners")

using .Ecosystems: Metrics
using .Metrics.Abstract: Metric
using .Metrics.Outcomes.Abstract: OutcomeMetric
using .Metrics.Outcomes.Types.NumbersGame: NumbersGame as NumbersGameMetrics
using .Metrics.Observations.Abstract: ObservationMetric
using .Metrics.Species.Abstract: SpeciesMetric
using .Metrics.Interactions.Abstract: InteractionMetric
using .Metrics.Evaluations.Abstract: EvaluationMetric
using .Metrics.Evaluations.Types: TestBasedFitness, AllSpeciesFitness
println("loaded metrics")

using .Ecosystems: Interactions
using .Interactions.Abstract: Interaction
using .Interactions.Methods.Interact: interact
using .Interactions.Methods: NumbersGame as NumbersGameMethods
using .Interactions: Domains, MatchMakers, Observers, Results, Environments
using .Interactions.Types: BasicInteraction 
println("loaded interactions")

using .Interactions: Domains
using .Domains.Abstract: Domain
using .Domains.Types.NumbersGame: NumbersGameDomain
println("loaded domains")

using .Interactions: MatchMakers
using .MatchMakers.Abstract: MatchMaker
using .MatchMakers.AllvsAll: AllvsAllMatchMaker 
println("loaded matchmakers")

using .Interactions: Observers
using .Observers.Abstract: Observer, Observation
using .Observers.Interfaces: create_observation
using .Observers.Types.Basic: BasicObserver, BasicObservation
using .Observers.Types.Null: NullObservation
println("loaded observers")

using .Interactions: Results
using .Results: Result
println("loaded results")

using .Interactions: Environments
using .Environments.Abstract: Environment, EnvironmentCreator
using .Environments.Interfaces: create_environment, next!, get_outcome_set, is_active, observe! #
using .Environments.Types.Stateless: StatelessEnvironment, StatelessEnvironmentCreator #
println("loaded environments")

using .Ecosystems: Jobs
using .Jobs.Abstract: Job, JobCreator
using .Jobs.Interfaces: create_jobs
using .Jobs.Basic: BasicJob, BasicJobCreator 
println("loaded jobs")

using .Ecosystems.Performers: Performers
using .Performers.Abstract: Performer
using .Performers.Interfaces: perform
using .Performers.Basic: BasicPerformer
println("loaded performers")

using .Ecosystems: Measurements
using .Measurements.Abstract: Measurement
using .Measurements: BasicStatisticalMeasurement
println("loaded measurements")

using .Ecosystems: Reporters
using .Reporters.Abstract: Reporter
using .Reporters.Interfaces: create_report, measure
using .Reporters.Types.Basic: BasicReporter, BasicReport
using .Reporters.Types.Runtime: RuntimeReporter, RuntimeReport
println("loaded reporters")

using .Ecosystems: Archivers
using .Archivers.Abstract: Archiver
using .Archivers.Interfaces: archive!
using .Archivers.Basic: BasicArchiver
println("loaded archivers")

end
