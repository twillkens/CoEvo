using Test

include("../src/CoEvo.jl")
using .CoEvo
using .CoEvo.NumbersGame: NumbersGameProblem, Sum

species_cfgs = [SpeciesCfg(), SpeciesCfg()]
problem = NumbersGameProblem(:Sum)
domain_cfgs = [DomainCfg()]
job_cfg = JobCfg(domain_cfgs)
eco_cfg = EcoCfg(species_cfgs, job_cfg)
println(eco_cfg())