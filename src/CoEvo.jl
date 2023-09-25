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
       DefaultArchiver

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
using .Ecosystems.Species.Genotypes: VectorGenotypeConfiguration
using .Ecosystems.Species.Phenotypes: DefaultPhenotypeConfiguration
using .Ecosystems.Species.Individuals: AsexualIndividualConfiguration, 
                                     SexualIndividualConfiguration
using .Ecosystems.Species.Evaluations: ScalarFitnessEvaluationConfiguration
using .Ecosystems.Species.Replacers: IdentityReplacer, GenerationalReplacer
using .Ecosystems.Species.Selectors: IdentitySelector, FitnessProportionateSelector
using .Ecosystems.Species.Recombiners: CloneRecombiner
using .Ecosystems.Species.Mutators: DefaultMutator
using .Ecosystems.Species.Reporters: CohortMetricReporter
using .Ecosystems.Jobs: InteractionJobConfiguration
using .Ecosystems.Jobs.Domains: InteractiveDomainConfiguration
using .Ecosystems.Jobs.Domains.MatchMakers: AllvsAllMatchMaker
using .Ecosystems.Jobs.Domains.Problems.NumbersGame: NumbersGame
using .Ecosystems.Archivers: DefaultArchiver
using .Ecosystems.Reporters: RuntimeReporter

end
