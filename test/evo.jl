using Test

include("../src/CoEvo.jl")
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
eco_cfg = EcoCfg(species_cfgs, job_cfg)
eco = eco_cfg()
observations = eco_cfg.job_cfg(eco)
evolve!(eco_cfg, n_gen=10)