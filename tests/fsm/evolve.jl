using Test
using Random: AbstractRNG
using StableRNGs: StableRNG
#include("../../src/CoEvo.jl")
using .CoEvo
using .Metrics.Concrete.Outcomes.PredictionGameOutcomeMetrics: CooperativeMatching, Competitive
using .Metrics.Concrete.Outcomes.PredictionGameOutcomeMetrics: CooperativeMismatching
using .FiniteStateMachineMutators: FiniteStateMachineMutator

@testset "Evolve" begin

@testset "LinguisticPredictionGame: Roulette" begin

function cont_pred_eco_creator(;
    id::String = "LinguisticPredictionGame",
    trial::Int = 1,
    rng::AbstractRNG = StableRNG(42),
    n_pop::Int = 50,
    species_id1::String = "Host",
    species_id2::String = "Mutualist",
    species_id3::String = "Parasite",
    interaction_id1::String = "Host-Mutualist-CooperativeMatching",
    interaction_id2::String = "Host-Parasite-Competitive",
    n_elite::Int = 0,
    n_workers::Int = 1,
)
    eco_creator = BasicEcosystemCreator(
        id = id,
        trial = trial,
        rng = rng,
        species_creators = Dict(
            species_id1 => BasicSpeciesCreator(
                id = species_id1,
                n_pop = n_pop,
                geno_creator = FiniteStateMachineGenotypeCreator(),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = ScalarFitnessEvaluator(maximize = true),
                replacer = GenerationalReplacer(n_elite = n_elite),
                selector = FitnessProportionateSelector(n_parents = n_pop),
                recombiner = CloneRecombiner(),
                mutators = [FiniteStateMachineMutator()]
            ),
            species_id2 => BasicSpeciesCreator(
                id = species_id2,
                n_pop = n_pop,
                geno_creator = FiniteStateMachineGenotypeCreator(),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = ScalarFitnessEvaluator(maximize = true),
                replacer = GenerationalReplacer(n_elite = n_elite),
                selector = FitnessProportionateSelector(n_parents = n_pop),
                recombiner = CloneRecombiner(),
                mutators = [FiniteStateMachineMutator()]
            ),
            species_id3 => BasicSpeciesCreator(
                id = species_id3,
                n_pop = n_pop,
                geno_creator = FiniteStateMachineGenotypeCreator(),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = ScalarFitnessEvaluator(maximize = true),
                replacer = GenerationalReplacer(n_elite = n_elite),
                selector = FitnessProportionateSelector(n_parents = n_pop),
                recombiner = CloneRecombiner(),
                mutators = [FiniteStateMachineMutator()]
            ),
        ),
        job_creator = BasicJobCreator(
            n_workers = 1,
            interactions = Dict(
                interaction_id1 => BasicInteraction(
                    id = interaction_id1,
                    environment_creator = LinguisticPredictionGameEnvironmentCreator(
                        domain = LinguisticPredictionGameDomain(
                            CooperativeMatching()
                        ),
                    ),
                    species_ids = [species_id1, species_id2],
                    matchmaker = AllvsAllMatchMaker(type = :plus),
                ),
                interaction_id2 => BasicInteraction(
                    id = interaction_id2,
                    environment_creator = LinguisticPredictionGameEnvironmentCreator(
                        domain = LinguisticPredictionGameDomain(
                            Competitive()
                        ),
                    ),
                    species_ids = [species_id1, species_id3],
                    matchmaker = AllvsAllMatchMaker(type = :plus),
                ),
            ),
        ),
        performer = BasicPerformer(n_workers = n_workers),
        reporters = Reporter[
            # BasicReporter(metric = GenotypeSize()),
        ],
        archiver = BasicArchiver(),
        runtime_reporter = RuntimeReporter(print_interval = 0),
    )
    return eco_creator
end


eco_creator = cont_pred_eco_creator(n_pop = 50, n_workers = 1)
eco = evolve!(eco_creator, n_gen = 5)
@test length(eco.species) == 3

end

@testset "LinguisticPredictionGame: Disco" begin

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
                geno_creator = FiniteStateMachineGenotypeCreator(),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = NSGAIIEvaluator(
                    maximize = true,
                    perform_disco = true
                ),
                replacer = TruncationReplacer(type = :plus, n_truncate = 25),
                selector = TournamentSelector(
                    μ = n_pop, tournament_size = 3, selection_func=argmin
                ),
                recombiner = CloneRecombiner(),
                mutators = [FiniteStateMachineMutator()]
            ),
            species_id2 => BasicSpeciesCreator(
                id = species_id2,
                n_pop = n_pop,
                geno_creator = FiniteStateMachineGenotypeCreator(),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = NSGAIIEvaluator(
                    maximize = true,
                    perform_disco = true
                ),
                replacer = TruncationReplacer(type = :plus, n_truncate = 25),
                selector = TournamentSelector(
                    μ = n_pop, tournament_size = 3, selection_func=argmin
                ),
                recombiner = CloneRecombiner(),
                mutators = [FiniteStateMachineMutator()]
            ),
            species_id3 => BasicSpeciesCreator(
                id = species_id3,
                n_pop = n_pop,
                geno_creator = FiniteStateMachineGenotypeCreator(),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = NSGAIIEvaluator(),
                replacer = TruncationReplacer(type = :plus, n_truncate = 25),
                selector = TournamentSelector(μ = n_pop, tournament_size = 3),
                recombiner = CloneRecombiner(),
                mutators = [FiniteStateMachineMutator()]
            ),
        ),
        job_creator = BasicJobCreator(
            n_workers = 1,
            interactions = Dict(
                interaction_id1 => BasicInteraction(
                    id = interaction_id1,
                    environment_creator = LinguisticPredictionGameEnvironmentCreator(
                        LinguisticPredictionGameDomain(
                            CooperativeMismatching()
                        ),
                    ),
                    species_ids = [species_id1, species_id2],
                    matchmaker = AllvsAllMatchMaker(type = :plus),
                ),
                interaction_id2 => BasicInteraction(
                    id = interaction_id2,
                    environment_creator = LinguisticPredictionGameEnvironmentCreator(
                        LinguisticPredictionGameDomain(
                            Competitive()
                        ),
                    ),
                    species_ids = [species_id1, species_id3],
                    matchmaker = AllvsAllMatchMaker(type = :plus),
                ),
            ),
        ),
        performer = BasicPerformer(n_workers = n_workers),
        reporters = Reporter[
            # BasicReporter(metric = GenotypeSize()),
            # BasicReporter(metric = AllSpeciesFitness()),
        ],
        archiver = BasicArchiver(),
        runtime_reporter = RuntimeReporter(print_interval = 0),
    )
    return eco_creator
end


eco_creator = cont_pred_eco_creator(n_pop = 50, n_workers = 1)
eco = evolve!(eco_creator, n_gen=5)
@test length(eco.species) == 3

end

end