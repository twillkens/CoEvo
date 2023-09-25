using Test

include("../src/CoEvo.jl")
using StableRNGs: StableRNG
using DataStructures: OrderedDict
using .CoEvo
using .CoEvo.NumbersGame: NumbersGameProblem, Sum


n_pop = 1000

species_id1 = "a"
species_id2 = "b"
domain_id = "NumbersGame{Sum}"

eco_cfg = CoevolutionaryEcosystemConfiguration(
    id = "test",
    trial = 1,
    rng = StableRNG(42),
    species_cfgs = OrderedDict(
        species_id1 => BasicSpeciesConfiguration(
            id = species_id1,
            geno_cfg = VectorGenotypeConfiguration{Float64}(default_vector = fill(0.0, 10)),
            pheno_cfg = DefaultPhenotypeConfiguration(),
            indiv_cfg = AsexualIndividualConfiguration(),
            eval_cfg = ScalarFitnessEvaluationConfiguration(),
            replacer = GenerationalReplacer(),
            selector = FitnessProportionateSelector(n_parents = 2),
            recombiner = CloneRecombiner(),
            mutators = [DefaultMutator()],
            reporters = [SumGenotypeReporter()],
        ),
        species_id2 => BasicSpeciesConfiguration(
            id = species_id2,
            geno_cfg = VectorGenotypeConfiguration{Float64}(default_vector = fill(0.0, 10)),
            pheno_cfg = DefaultPhenotypeConfiguration(),
            indiv_cfg = AsexualIndividualConfiguration(),
            eval_cfg = ScalarFitnessEvaluationConfiguration(),
            replacer = GenerationalReplacer(),
            selector = FitnessProportionateSelector(n_parents = 2),
            recombiner = CloneRecombiner(),
            mutators = [DefaultMutator()],
            reporters = [SumGenotypeReporter()],
        ),
    ),
    job_cfg = InteractionJobConfiguration(
        n_workers = 1,
        dom_cfgs = OrderedDict(
            domain_id => InteractiveDomainConfiguration(
                id = domain_id,
                problem = NumbersGameProblem(:Sum),
                species_ids = [species_id1, species_id2],
                obs_cfg = OutcomeObservationConfiguration(),
                matchmaker = AllvsAllMatchMaker(type = :plus),
                reporters = Reporter[]
            ),
        ),
    ),
    archiver = DefaultArchiver(),
    indiv_id_counter = Counter(),
    gene_id_counter = Counter(),
    runtime_reporter = RuntimeReporter(),
)

evolve!(eco_cfg, n_gen=1000)