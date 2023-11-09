module Names

# Counters
export Counter, count!
using ..Counters: Counter, count!

export BasicCounter
using ..Counters.Basic: BasicCounter

# GenotypeCreators
export Genotype, GenotypeCreator, create_genotypes, get_size, minimize
using ..Genotypes: Genotype, GenotypeCreator, create_genotypes, get_size, minimize

export BasicVectorGenotype, BasicVectorGenotypeCreator
using ..Genotypes.Vectors: BasicVectorGenotype, BasicVectorGenotypeCreator

export FiniteStateMachineGenotype, FunctionGraphGenotypeCreator
using ..Genotypes.FiniteStateMachines: FiniteStateMachineGenotype
using ..Genotypes.FiniteStateMachines: FiniteStateMachineGenotypeCreator

export GnarlNetworkGenotype, GnarlNetworkGenotypeCreator
using ..Genotypes.GnarlNetworks: GnarlNetworkGenotype, GnarlNetworkGenotypeCreator

export FunctionGraphGenotype, FunctionGraphGenotypeCreator
using ..Genotypes.FunctionGraphs: FunctionGraphGenotype, FunctionGraphGenotypeCreator

# Mutators
export Mutator, mutate
using ..Mutators: Mutator, mutate

export IdentityMutator
using ..Mutators.Identity: IdentityMutator

export BasicVectorMutator
using ..Mutators.Vectors: BasicVectorMutator

export FiniteStateMachineMutator
using ..Mutators.FiniteStateMachines: FiniteStateMachineMutator

export FunctionGraphMutator
using ..Mutators.FunctionGraphs: FunctionGraphMutator

export GnarlNetworkMutator
using ..Mutators.GnarlNetworks: GnarlNetworkMutator

# Recombiners
export Recombiner, recombine
using ..Recombiners: Recombiner, recombine

export CloneRecombiner
using ..Recombiners.Clone: CloneRecombiner

# IndividualCreators
export Individual, IndividualCreator, create_individuals
using ..Individuals: Individual, IndividualCreator, create_individuals

export BasicIndividualCreator
using ..Individuals.Basic: BasicIndividualCreator

# Species
export AbstractSpecies
using ..Species: AbstractSpecies

export BasicSpecies
using ..Species.Basic: BasicSpecies

# PhenotypeCreators
export Phenotype, PhenotypeCreator, create_phenotype, act!, reset!
using ..Phenotypes: Phenotype, PhenotypeCreator, create_phenotype, act!, reset!

export DefaultPhenotypeCreator
using ..Phenotypes.Defaults: DefaultPhenotypeCreator

export BasicVectorPhenotype
using ..Phenotypes.Vectors: BasicVectorPhenotype

export GeneticProgramPhenotype
using ..Phenotypes.GeneticPrograms: GeneticProgramPhenotype

export GnarlNetworkPhenotype
using ..Phenotypes.GnarlNetworks: GnarlNetworkPhenotype

export FiniteStateMachinePhenotype
using ..Phenotypes.FiniteStateMachines: FiniteStateMachinePhenotype

export LinearizedFunctionGraphPhenotype, LinearizedFunctionGraphPhenotypeCreator
using ..Phenotypes.FunctionGraphs.Linearized: LinearizedFunctionGraphPhenotype
using ..Phenotypes.FunctionGraphs.Linearized: LinearizedFunctionGraphPhenotypeCreator

# Criteria
export Criterion, Maximize, Minimize
using ..Criteria: Criterion, Maximize, Minimize

# Evaluators
export Evaluator, evaluate
using ..Evaluators: Evaluator, evaluate

export ScalarFitnessEvaluation, ScalarFitnessEvaluator
using ..Evaluators.ScalarFitness: ScalarFitnessEvaluation, ScalarFitnessEvaluator

export NSGAIIEvaluation, NSGAIIEvaluator
using ..Evaluators.NSGAII: NSGAIIEvaluation, NSGAIIEvaluator

# Replacers
export Replacer, replace
using ..Replacers: Replacer, replace

export TruncationReplacer
using ..Replacers.Truncation: TruncationReplacer

export GenerationalReplacer
using ..Replacers.Generational: GenerationalReplacer

# Selectors
export Selector, select
using ..Selectors: Selector, select

export TournamentSelector
using ..Selectors.Tournament: TournamentSelector

export FitnessProportionateSelector
using ..Selectors.FitnessProportionate: FitnessProportionateSelector

# SpeciesCreators
export SpeciesCreator, create_species
using ..SpeciesCreators: SpeciesCreator, create_species

export BasicSpeciesCreator
using ..SpeciesCreators.Basic: BasicSpeciesCreator

# MatchMakers
export MatchMaker, make_matches
using ..MatchMakers: MatchMaker, make_matches

export AllVersusAllMatchMaker
using ..MatchMakers.AllVersusAll: AllVersusAllMatchMaker

export OneVersusAllMatchMaker
using ..MatchMakers.OneVersusAll: OneVersusAllMatchMaker

# Domains
export Domain
using ..Domains: Domain

export NumbersGameDomain
using ..Domains.NumbersGame: NumbersGameDomain

export PredictionGameDomain
using ..Domains.PredictionGame: PredictionGameDomain

# Environments
export Environment, create_environment, get_outcome_set, is_active, observe!, step!
using ..Environments: Environment, create_environment, get_outcome_set, is_active, observe!
using ..Environments: step!

export StatelessEnvironmentCreator
using ..Environments.Stateless: StatelessEnvironmentCreator

export ContinuousPredictionGameEnvironmentCreator, ContinuousPredictionGameEnvironment
using ..Environments.ContinuousPredictionGame: ContinuousPredictionGameEnvironment
using ..Environments.ContinuousPredictionGame: ContinuousPredictionGameEnvironmentCreator

export CollisionGameEnvironment, CollisionGameEnvironmentCreator
using ..Environments.CollisionGame: CollisionGameEnvironment
using ..Environments.CollisionGame: CollisionGameEnvironmentCreator

# Interactions
export Interaction, interact
using ..Interactions: Interaction, interact

export BasicInteraction
using ..Interactions.Basic: BasicInteraction

# JobCreators
export Job, JobCreator, create_jobs
using ..Jobs: Job, JobCreator, create_jobs

export BasicJobCreator
using ..Jobs.Basic: BasicJobCreator

# Performers
export Performer, perform
using ..Performers: Performer, perform

export BasicPerformer
using ..Performers.Basic

export CachePerformer
using ..Performers.Cache: CachePerformer

# Metrics
export Metrics, Metric, Measurement, Aggregator, measure, get_name, aggregate
using ..Metrics: Metrics, Metric, Measurement, Aggregator, measure, get_name, aggregate

export NullMetric, RuntimeMetric, GlobalStateMetric, BasicMeasurement, BasicGroupMeasurement
using ..Metrics.Common: NullMetric, RuntimeMetric, GlobalStateMetric
using ..Metrics.Common: BasicMeasurement, BasicGroupMeasurement

export BasicFeatureAggregator, BasicQuantileAggregator, OneSampleTTestAggregator, HigherMomentAggregator
using ..Metrics.Aggregators: BasicFeatureAggregator, BasicQuantileAggregator
using ..Metrics.Aggregators: OneSampleTTestAggregator, HigherMomentAggregator

export EvaluationMetric, FitnessEvaluationMetric
using ..Metrics.Evaluations: EvaluationMetric, FitnessEvaluationMetric

export IndividualMetric
using ..Metrics.Individuals: IndividualMetric

export GenotypeMetric, SizeGenotypeMetric, SumGenotypeMetric
using ..Metrics.Genotypes: GenotypeMetric, SizeGenotypeMetric, SumGenotypeMetric

# StateCreators

export State, StateCreator
using ..States: State, StateCreator

export BasicCoevolutionaryState, BasicCoevolutionaryStateCreator
using ..States.Basic: BasicCoevolutionaryState, BasicCoevolutionaryStateCreator

# Reporters
export Reporter, create_report
using ..Reporters: Reporter, create_report

export BasicReporter
using ..Reporters.Basic: BasicReporter

export RuntimeReporter
using ..Reporters.Runtime: RuntimeReporter

# Archivers
export Archiver, archive!
using ..Archivers: Archiver, archive!

export BasicArchiver
using ..Archivers.Basic: BasicArchiver

# Ecosystems
export Ecosystem, EcosystemCreator, evolve!, create_ecosystem
using ..Ecosystems: Ecosystem, EcosystemCreator, evolve!, create_ecosystem

export BasicEcosystem, BasicEcosystemCreator
using ..Ecosystems.Basic: BasicEcosystem, BasicEcosystemCreator

end