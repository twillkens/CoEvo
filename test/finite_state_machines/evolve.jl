using Test
using Random: AbstractRNG
using StableRNGs: StableRNG
#include("../../src/CoEvo.jl")
using .CoEvo
using .FiniteStateMachineMutators: FiniteStateMachineMutator

@testset "Evolve" begin

@testset "LinguisticPredictionGame: Roulette" begin

function cont_pred_eco_creator(;
    id::String = "LinguisticPredictionGame",
    trial::Int = 1,
    random_number_generator::AbstractRNG = StableRNG(42),
    n_population::Int = 50,
    species_id1::String = "Host",
    species_id2::String = "Mutualist",
    species_id3::String = "Parasite",
    interaction_id1::String = "Host-Mutualist-CooperativeMatching",
    interaction_id2::String = "Host-Parasite-Competitive",
    n_elite::Int = 0,
    n_workers::Int = 1,
    cohorts::Vector{Symbol} = [:population, :children],
)
    ecosystem_creator = BasicEcosystemCreator(
        id = id,
        trial = trial,
        random_number_generator = random_number_generator,
        species_creators = [
            BasicSpeciesCreator(
                id = species_id1,
                n_population = n_population,
                genotype_creator = FiniteStateMachineGenotypeCreator(),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = ScalarFitnessEvaluator(maximize = true),
                replacer = GenerationalReplacer(n_elite = n_elite),
                selector = FitnessProportionateSelector(n_parents = n_population),
                recombiner = CloneRecombiner(),
                mutators = [FiniteStateMachineMutator()]
            ),
            BasicSpeciesCreator(
                id = species_id2,
                n_population = n_population,
                genotype_creator = FiniteStateMachineGenotypeCreator(),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = ScalarFitnessEvaluator(maximize = true),
                replacer = GenerationalReplacer(n_elite = n_elite),
                selector = FitnessProportionateSelector(n_parents = n_population),
                recombiner = CloneRecombiner(),
                mutators = [FiniteStateMachineMutator()]
            ),
            BasicSpeciesCreator(
                id = species_id3,
                n_population = n_population,
                genotype_creator = FiniteStateMachineGenotypeCreator(),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = ScalarFitnessEvaluator(maximize = true),
                replacer = GenerationalReplacer(n_elite = n_elite),
                selector = FitnessProportionateSelector(n_parents = n_population),
                recombiner = CloneRecombiner(),
                mutators = [FiniteStateMachineMutator()]
            ),
        ],
        job_creator = BasicJobCreator(
            n_workers = 1,
            interactions = [
                BasicInteraction(
                    id = interaction_id1,
                    environment_creator = LinguisticPredictionGameEnvironmentCreator(
                        domain = PredictionGameDomain(
                            :Affinitive
                        ),
                    ),
                    species_ids = [species_id1, species_id2],
                    matchmaker = AllvsAllMatchMaker(cohorts = cohorts),
                ),
                BasicInteraction(
                    id = interaction_id2,
                    environment_creator = LinguisticPredictionGameEnvironmentCreator(
                        domain = PredictionGameDomain(
                            :Adversarial
                        ),
                    ),
                    species_ids = [species_id1, species_id3],
                    matchmaker = AllvsAllMatchMaker(cohorts = cohorts),
                ),
            ],
        ),
        performer = BasicPerformer(n_workers = n_workers),
        state_creator = BasicCoevolutionaryStateCreator(),
        reporters = Reporter[
            # BasicReporter(metric = GenotypeSize()),
        ],
        archiver = BasicArchiver(),
        runtime_reporter = RuntimeReporter(print_interval = 0),
    )
    return ecosystem_creator
end


ecosystem_creator = cont_pred_eco_creator(n_population = 50, n_workers = 1)
eco = evolve!(ecosystem_creator, n_generations = 5)
@test length(eco.species) == 3

end

@testset "LinguisticPredictionGame: Disco" begin

function cont_pred_eco_creator(;
    id::String = "Symbolic Regression",
    trial::Int = 1,
    random_number_generator::AbstractRNG = StableRNG(42),
    n_population::Int = 50,
    species_id1::String = "Host",
    species_id2::String = "Mutualist",
    species_id3::String = "Parasite",
    interaction_id1::String = "Host-Mutualist-CooperativeMatching",
    interaction_id2::String = "Host-Parasite-Competitive",
    n_elite::Int = 0,
    n_workers::Int = 1,
    cohorts::Vector{Symbol} = [:population, :children],
    n_truncate::Int = 25,
    tournament_size::Int = 3,
)
    ecosystem_creator = BasicEcosystemCreator(
        id = id,
        trial = trial,
        random_number_generator = random_number_generator,
        species_creators = [
            BasicSpeciesCreator(
                id = species_id1,
                n_population = n_population,
                genotype_creator = FiniteStateMachineGenotypeCreator(),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = NSGAIIEvaluator(
                    maximize = true,
                    perform_disco = true
                ),
                replacer = TruncationReplacer(n_truncate = n_truncate),
                selector = TournamentSelector(
                    n_parents = n_population, tournament_size = tournament_size
                ),
                recombiner = CloneRecombiner(),
                mutators = [FiniteStateMachineMutator()]
            ),
            BasicSpeciesCreator(
                id = species_id2,
                n_population = n_population,
                genotype_creator = FiniteStateMachineGenotypeCreator(),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = NSGAIIEvaluator(
                    maximize = true,
                    perform_disco = true
                ),
                replacer = TruncationReplacer(n_truncate = n_truncate),
                selector = TournamentSelector(
                    n_parents = n_population, tournament_size = tournament_size
                ),
                recombiner = CloneRecombiner(),
                mutators = [FiniteStateMachineMutator()]
            ),
            BasicSpeciesCreator(
                id = species_id3,
                n_population = n_population,
                genotype_creator = FiniteStateMachineGenotypeCreator(),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = NSGAIIEvaluator(),
                replacer = TruncationReplacer(n_truncate = n_truncate),
                selector = TournamentSelector(
                    n_parents = n_population, tournament_size = tournament_size
                ),
                recombiner = CloneRecombiner(),
                mutators = [FiniteStateMachineMutator()]
            ),
        ],
        job_creator = BasicJobCreator(
            n_workers = 1,
            interactions = [
                BasicInteraction(
                    id = interaction_id1,
                    environment_creator = LinguisticPredictionGameEnvironmentCreator(
                        PredictionGameDomain(:Affinitive),
                    ),
                    species_ids = [species_id1, species_id2],
                    matchmaker = AllvsAllMatchMaker(cohorts = cohorts),
                ),
                BasicInteraction(
                    id = interaction_id2,
                    environment_creator = LinguisticPredictionGameEnvironmentCreator(
                        PredictionGameDomain(:Adversarial),
                    ),
                    species_ids = [species_id1, species_id3],
                    matchmaker = AllvsAllMatchMaker(cohorts = cohorts),
                ),
            ],
        ),
        performer = BasicPerformer(n_workers = n_workers),
        state_creator = BasicCoevolutionaryStateCreator(),
        reporters = Reporter[
            # BasicReporter(metric = GenotypeSize()),
            # BasicReporter(metric = AllSpeciesFitness()),
        ],
        archiver = BasicArchiver(),
        runtime_reporter = RuntimeReporter(print_interval = 0),
    )
    return ecosystem_creator
end


ecosystem_creator = cont_pred_eco_creator(n_population = 50, n_workers = 1)
eco = evolve!(ecosystem_creator, n_generations=5)
@test length(eco.species) == 3

end

end