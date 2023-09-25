module CoEvo


export evolve!

export Reporter

export Counter

export RuntimeReporter, CohortMetricReporter

export GenotypeSum, GenotypeSize, EvaluationFitness

export CoevolutionaryEcosystemConfiguration

export BasicSpeciesConfiguration

export VectorGenotypeConfiguration

export DefaultPhenotypeConfiguration

export AsexualIndividualConfiguration, SexualIndividualConfiguration

export ScalarFitnessEvaluationConfiguration

export IdentityReplacer, GenerationalReplacer

export IdentitySelector, FitnessProportionateSelector

export CloneRecombiner

export DefaultMutator

export SizeGenotypeReporter, SumGenotypeReporter, FitnessEvaluationReporter

export InteractionJobConfiguration

export InteractiveDomainConfiguration

export AllvsAllMatchMaker

export NumbersGame

export OutcomeObservationConfiguration

export DefaultArchiver

include("abstract/abstract.jl")

include("utilities/utilities.jl")

include("ecosystems/ecosystems.jl")

using .Abstract: Reporter

using .Utilities.Counters: Counter

using .Utilities.Metrics: GenotypeSum, GenotypeSize, EvaluationFitness

using .Ecosystems: CoevolutionaryEcosystemConfiguration, evolve!

using .Ecosystems.Observations: OutcomeObservationConfiguration

using .Ecosystems.Species: BasicSpeciesConfiguration

using .Ecosystems.Species.Genotypes: VectorGenotypeConfiguration

using .Ecosystems.Species.Phenotypes: DefaultPhenotypeConfiguration

using .Ecosystems.Species.Individuals: AsexualIndividualConfiguration

using .Ecosystems.Species.Individuals: SexualIndividualConfiguration

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