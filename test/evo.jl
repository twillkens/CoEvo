using Test

include("../src/CoEvo.jl")
using StableRNGs: StableRNG
using DataStructures: OrderedDict
using .CoEvo: NumbersGameProblem, Sum, SpeciesCfg, DomainCfg, JobCfg, EcoCfg
using .CoEvo: BasicSpeciesConfiguration, InteractiveDomainConfiguration, InteractionJobConfiguration
using .CoEvo: OutcomeObservationConfiguration, OutcomeObsCfg
using .CoEvo: VectorGenotypeConfiguration, VectorGenoCfg, evolve!

species_cfgs = [
    BasicSpeciesConfiguration(
        geno_cfg = VectorGenotypeConfiguration([0.5])
    ),
    BasicSpeciesConfiguration(
        geno_cfg = VectorGenotypeConfiguration([1.0])
    )
]

            
    
problem = NumbersGameProblem(:Sum)
domain_cfgs = [DomainCfg()]
job_cfg = JobCfg(domain_cfgs)

CoEvo.Ecosystems.CoevolutionaryEcosystemConfiguration(
    "hi", 
    1, 
    StableRNG(42), 
    OrderedDict("a" => species_cfgs[1], "b" => species_cfgs[2]), 
    job_cfg, 
    Main.CoEvo.Ecosystems.Archivers.DefaultArchiver(), 
    CoEvo.Ecosystems.Species.Utilities.Counter(),
    CoEvo.Ecosystems.Species.Utilities.Counter(),
    CoEvo.Ecosystems.Reporters.RuntimeReporter()
)
eco_cfg = EcoCfg(species_cfgs, job_cfg)
eco = eco_cfg()
observations = eco_cfg.job_cfg(eco)
evolve!(eco_cfg, n_gen=10)