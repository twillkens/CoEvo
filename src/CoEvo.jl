module CoEvo

export evolve!

export Reporter

export Counter

export CoevolutionaryEcosystemConfiguration, EcoCfg

export BasicSpeciesConfiguration, SpeciesCfg

export VectorGenotypeConfiguration, VectorGenoCfg

export DefaultPhenotypeConfiguration, DefaultPhenoCfg

export AsexualIndividualConfiguration, AsexualIndivCfg

export SexualIndividualConfiguration, SexualIndivCfg

export ScalarFitnessEvaluationConfiguration, ScalarFitEvalCfg

export IdentityReplacer, GenerationalReplacer

export IdentitySelector, FitnessProportionateSelector

export CloneRecombiner

export DefaultMutator

export SizeGenotypeReporter, SumGenotypeReporter, FitnessEvaluationReporter

export InteractionJobConfiguration, JobCfg

export InteractiveDomainConfiguration, DomainCfg

export AllvsAllMatchMaker

export NumbersGame

export OutcomeObservationConfiguration, OutcomeObsCfg

export DefaultArchiver

export RuntimeReporter

include("abstract/abstract.jl")

include("utilities/utilities.jl")

include("ecosystems/ecosystems.jl")

using .Abstract: Reporter

using .Utilities.Counters: Counter

using .Ecosystems: CoevolutionaryEcosystemConfiguration, evolve!
const EcoCfg = CoevolutionaryEcosystemConfiguration

using .Ecosystems.Observations: OutcomeObservationConfiguration
const OutcomeObsCfg = OutcomeObservationConfiguration

using .Ecosystems.Species: BasicSpeciesConfiguration
const SpeciesCfg = BasicSpeciesConfiguration

using .Ecosystems.Species.Genotypes: VectorGenotypeConfiguration
const VectorGenoCfg = VectorGenotypeConfiguration

using .Ecosystems.Species.Phenotypes: DefaultPhenotypeConfiguration
const DefaultPhenoCfg = DefaultPhenotypeConfiguration

using .Ecosystems.Species.Individuals: AsexualIndividualConfiguration
const AsexualIndivCfg = AsexualIndividualConfiguration

using .Ecosystems.Species.Individuals: SexualIndividualConfiguration
const SexualIndivCfg = SexualIndividualConfiguration

using .Ecosystems.Species.Evaluations: ScalarFitnessEvaluationConfiguration
const ScalarFitEvalCfg = ScalarFitnessEvaluationConfiguration

using .Ecosystems.Species.Replacers: IdentityReplacer, GenerationalReplacer

using .Ecosystems.Species.Selectors: IdentitySelector, FitnessProportionateSelector

using .Ecosystems.Species.Recombiners: CloneRecombiner

using .Ecosystems.Species.Mutators: DefaultMutator

using .Ecosystems.Species.Reporters: SizeGenotypeReporter
using .Ecosystems.Species.Reporters: FitnessEvaluationReporter
using .Ecosystems.Species.Reporters: SumGenotypeReporter

using .Ecosystems.Jobs: InteractionJobConfiguration
const JobCfg = InteractionJobConfiguration

using .Ecosystems.Jobs.Domains: InteractiveDomainConfiguration
const DomainCfg = InteractiveDomainConfiguration

using .Ecosystems.Jobs.Domains.MatchMakers: AllvsAllMatchMaker

using .Ecosystems.Jobs.Domains.Problems.NumbersGame: NumbersGame

using .Ecosystems.Archivers: DefaultArchiver

using .Ecosystems.Reporters: RuntimeReporter

end