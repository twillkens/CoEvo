module CoEvo

export evolve!
export CoevolutionaryEcosystemConfiguration, EcoCfg
export OutcomeObservationConfiguration, OutcomeObsCfg
export BasicSpeciesConfiguration, SpeciesCfg
export VectorGenotypeConfiguration, VectorGenoCfg
export DefaultPhenotypeConfiguration, DefaultPhenoCfg
export AsexualIndividualConfiguration, AsexualIndivCfg
export SexualIndividualConfiguration, SexualIndivCfg
export ScalarFitnessEvaluationConfiguration, ScalarFitEvalCfg
export IdentityReplacer, IdentitySelector, CloneRecombiner
export InteractionJobConfiguration, JobCfg
export InteractiveDomainConfiguration, DomainCfg
export AllvsAllMatchMaker, NumbersGameProblem

include("abstract/abstract.jl")
include("utilities/utilities.jl")
include("ecosystems/ecosystems.jl")

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

using .Ecosystems.Species.Replacers: IdentityReplacer
using .Ecosystems.Species.Selectors: IdentitySelector
using .Ecosystems.Species.Recombiners: CloneRecombiner

using .Ecosystems.Jobs: InteractionJobConfiguration
const JobCfg = InteractionJobConfiguration

using .Ecosystems.Jobs.Domains: InteractiveDomainConfiguration
const DomainCfg = InteractiveDomainConfiguration

using .Ecosystems.Jobs.Domains.MatchMakers: AllvsAllMatchMaker
using .Ecosystems.Jobs.Domains.Problems: NumbersGameProblem
using .Ecosystems.Jobs.Domains.Problems.NumbersGame: Sum, Control, Gradient, Focusing, Relativism









end