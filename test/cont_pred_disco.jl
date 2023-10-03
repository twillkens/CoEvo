using Random: AbstractRNG
using StableRNGs: StableRNG
using DataStructures: OrderedDict
include("../src/CoEvo.jl")
using .CoEvo
using .Genotypes.GeneticPrograms.Utilities: Utilities as GPUtilities
using .GPUtilities: protected_division, Terminal, FuncAlias, protected_sine, if_less_then_else


function cont_pred_eco_creator(;
    id::String = "Symbolic Regression",
    trial::Int = 1,
    rng::AbstractRNG = StableRNG(42),
    n_pop::Int = 50,
    species_id1::String = "Host",
    species_id2::String = "Mutualist",
    species_id3::String = "Parasite",
    interaction_id1::String = "Host-Mutualist-CooperativeMatching",
    interaction_id2::String = "Host-Parasite-Competitive",
    n_elite::Int = 0,
    n_workers::Int = 1
)
    eco_creator = BasicEcosystemCreator(
        id = id,
        trial = trial,
        rng = rng,
        species_creators = Dict(
            species_id1 => BasicSpeciesCreator(
                id = species_id1,
                n_pop = n_pop,
                geno_creator = GeneticProgramGenotypeCreator(),
                pheno_creator = DefaultPhenotypeCreator(),
                evaluator = DiscoEvaluator(),
                replacer = TruncationReplacer(:plus),
                selector = TournamentSelector(μ = n_pop, tournament_size = 3),
                recombiner = CloneRecombiner(),
                mutators = [GeneticProgramMutator()]
            ),
            species_id2 => BasicSpeciesCreator(
                id = species_id2,
                n_pop = n_pop,
                geno_creator = GeneticProgramGenotypeCreator(),
                pheno_creator = DefaultPhenotypeCreator(),
                evaluator = DiscoEvaluator(),
                replacer = TruncationReplacer(:plus),
                selector = TournamentSelector(μ = n_pop, tournament_size = 3),
                recombiner = CloneRecombiner(),
                mutators = [GeneticProgramMutator()]
            ),
            species_id3 => BasicSpeciesCreator(
                id = species_id3,
                n_pop = n_pop,
                geno_creator = GeneticProgramGenotypeCreator(),
                pheno_creator = DefaultPhenotypeCreator(),
                evaluator = DiscoEvaluator(),
                replacer = TruncationReplacer(:plus),
                selector = TournamentSelector(μ = n_pop, tournament_size = 3),
                recombiner = CloneRecombiner(),
                mutators = [GeneticProgramMutator()]
            ),
        ),
        job_creator = BasicJobCreator(
            n_workers = 1,
            interactions = Dict(
                interaction_id1 => BasicInteraction(
                    id = interaction_id1,
                    environment_creator = TapeEnvironmentCreator(
                        ContinuousPredictionGameDomain(
                            CooperativeMatching()
                        ),
                        32
                    ),
                    species_ids = [species_id1, species_id2],
                    matchmaker = AllvsAllMatchMaker(type = :plus),
                ),
                interaction_id2 => BasicInteraction(
                    id = interaction_id2,
                    environment_creator = TapeEnvironmentCreator(
                        ContinuousPredictionGameDomain(
                            Competitive()
                        ),
                        32
                    ),
                    species_ids = [species_id1, species_id3],
                    matchmaker = AllvsAllMatchMaker(type = :plus),
                ),
            ),
        ),
        performer = BasicPerformer(n_workers = n_workers),
        reporters = Reporter[
            BasicReporter(metric = GenotypeSize()),
        ],
        archiver = BasicArchiver(),
    )
    return eco_creator
end


eco_creator = cont_pred_eco_creator(n_pop = 100, n_workers = 5)
eco = evolve!(eco_creator, n_gen=500)


