using Test
using Random: AbstractRNG
using StableRNGs: StableRNG
#include("../../src/CoEvo.jl")
#using CoEvo.Metrics.Concrete.Outcomes.CollisionGameOutcomeMetrics: Affinitive, Adversarial
#using CoEvo.Metrics.Concrete.Outcomes.CollisionGameOutcomeMetrics: Avoidant, Control as GnarlControl
#using CoEvo.Mutators.Types.GnarlNetworks: mutate_weights, add_node, remove_node, add_connection
#using CoEvo.Mutators.Types.GnarlNetworks: remove_connection, mutate

@testset "CollisionGame: Roulette" begin

function collision_game_eco_creator(;
    id::String = "CollisionGame",
    trial::Int = 1,
    rng::AbstractRNG = StableRNG(42),
    n_pop::Int = 50,
    host::String = "Host",
    mutualist::String = "Mutualist",
    parasite::String = "Parasite",
    host_mutualist_affinitive::String = "Host-Mutualist-Affinitive",
    host_parasite_adversarial::String = "Parasite-Host-Adversarial",
    parasite_mutualist_avoidant::String = "Parasite-Mutualist-Avoidant",
    n_elite::Int = 0,
    n_workers::Int = 1,
    episode_length::Int = 10,
    n_input_nodes::Int = 2,
    n_output_nodes::Int = 2,
    initial_distance::Float64 = 5.0
)
    eco_creator = BasicEcosystemCreator(
        id = id,
        trial = trial,
        rng = rng,
        species_creators = Dict(
            host => BasicSpeciesCreator(
                id = host,
                n_pop = n_pop,
                geno_creator = GnarlNetworkGenotypeCreator(
                    n_input_nodes = n_input_nodes, 
                    n_output_nodes = n_output_nodes
                ),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = ScalarFitnessEvaluator(maximize = true),
                replacer = GenerationalReplacer(n_elite = n_elite),
                selector = FitnessProportionateSelector(n_parents = n_pop),
                recombiner = CloneRecombiner(),
                mutators = [GnarlNetworkMutator()]
            ),
            parasite => BasicSpeciesCreator(
                id = parasite,
                n_pop = n_pop,
                geno_creator = GnarlNetworkGenotypeCreator(
                    n_input_nodes = n_input_nodes, 
                    n_output_nodes = n_output_nodes
                ),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = ScalarFitnessEvaluator(maximize = true),
                replacer = GenerationalReplacer(n_elite = n_elite),
                selector = FitnessProportionateSelector(n_parents = n_pop),
                recombiner = CloneRecombiner(),
                mutators = [GnarlNetworkMutator()]
            ),
            mutualist => BasicSpeciesCreator(
                id = mutualist,
                n_pop = n_pop,
                geno_creator = GnarlNetworkGenotypeCreator(
                    n_input_nodes = n_input_nodes, 
                    n_output_nodes = n_output_nodes
                ),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = ScalarFitnessEvaluator(maximize = true),
                replacer = GenerationalReplacer(n_elite = n_elite),
                selector = FitnessProportionateSelector(n_parents = n_pop),
                recombiner = CloneRecombiner(),
                mutators = [GnarlNetworkMutator()]
            ),
        ),
        job_creator = BasicJobCreator(
            n_workers = 1,
            interactions = Dict(
                host_mutualist_affinitive => BasicInteraction(
                    id = host_mutualist_affinitive,
                    environment_creator = CollisionGameEnvironmentCreator(
                        domain = CollisionGameDomain(
                            Affinitive(),
                        ),
                        initial_distance = initial_distance,
                        episode_length = episode_length
                    ),
                    species_ids = [host, mutualist],
                    matchmaker = AllvsAllMatchMaker(type = :plus),
                ),
                host_parasite_adversarial => BasicInteraction(
                    id = host_parasite_adversarial,
                    environment_creator = CollisionGameEnvironmentCreator(
                        domain = CollisionGameDomain(
                            Adversarial()
                        ),
                        initial_distance = initial_distance,
                        episode_length = episode_length
                    ),
                    species_ids = [parasite, host],
                    matchmaker = AllvsAllMatchMaker(type = :plus),
                ),
                parasite_mutualist_avoidant => BasicInteraction(
                    id = parasite_mutualist_avoidant,
                    environment_creator = CollisionGameEnvironmentCreator(
                        domain = CollisionGameDomain(
                            Avoidant()
                        ),
                        initial_distance = initial_distance,
                        episode_length = episode_length
                    ),
                    species_ids = [parasite, host],
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


eco_creator = collision_game_eco_creator(n_pop = 50, n_workers = 1)
eco = evolve!(eco_creator, n_gen = 5)
@test length(eco.species) == 3

end

@testset "CollisionGame: Disco" begin

function collision_game_disco_eco_creator(;
    id::String = "CollisionGame: Disco",
    trial::Int = 1,
    rng::AbstractRNG = StableRNG(42),
    n_pop::Int = 50,
    host::String = "Host",
    parasite::String = "Mutualist",
    mutualist::String = "Parasite",
    host_mutualist_affinitive::String = "Host-Mutualist-Affinitive",
    host_parasite_adversarial::String = "Host-Parasite-Adversarial",
    parasite_mutualist_avoidant::String = "Parasite-Mutualist-Avoidant",
    n_elite::Int = 0,
    n_workers::Int = 1,
    episode_length::Int = 10,
    initial_distance::Float64 = 5.0,
    n_input_nodes::Int = 2,
    n_output_nodes::Int = 2
)
    eco_creator = BasicEcosystemCreator(
        id = id,
        trial = trial,
        rng = rng,
        species_creators = Dict(
            host => BasicSpeciesCreator(
                id = host,
                n_pop = n_pop,
                geno_creator = GnarlNetworkGenotypeCreator(
                    n_input_nodes = n_input_nodes,
                    n_output_nodes = n_output_nodes 
                ),
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
                mutators = [GnarlNetworkMutator()]
            ),
            parasite => BasicSpeciesCreator(
                id = parasite,
                n_pop = n_pop,
                geno_creator = GnarlNetworkGenotypeCreator(
                    n_input_nodes = n_input_nodes, 
                    n_output_nodes = n_output_nodes
                ),
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
                mutators = [GnarlNetworkMutator()]
            ),
            mutualist => BasicSpeciesCreator(
                id = mutualist,
                n_pop = n_pop,
                geno_creator = GnarlNetworkGenotypeCreator(
                    n_input_nodes = n_input_nodes, 
                    n_output_nodes = n_output_nodes
                ),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = NSGAIIEvaluator(),
                replacer = TruncationReplacer(type = :plus, n_truncate = 25),
                selector = TournamentSelector(μ = n_pop, tournament_size = 3),
                recombiner = CloneRecombiner(),
                mutators = [GnarlNetworkMutator()]
            ),
        ),
        job_creator = BasicJobCreator(
            n_workers = 1,
            interactions = Dict(
                host_mutualist_affinitive => BasicInteraction(
                    id = host_mutualist_affinitive,
                    environment_creator = CollisionGameEnvironmentCreator(
                        domain = CollisionGameDomain(
                            Affinitive(),
                        ),
                        initial_distance = initial_distance,
                        episode_length = episode_length
                    ),
                    species_ids = [host, mutualist],
                    matchmaker = AllvsAllMatchMaker(type = :plus),
                ),
                host_parasite_adversarial => BasicInteraction(
                    id = host_parasite_adversarial,
                    environment_creator = CollisionGameEnvironmentCreator(
                        domain = CollisionGameDomain(
                            Adversarial()
                        ),
                        initial_distance = initial_distance,
                        episode_length = episode_length
                    ),
                    species_ids = [parasite, host],
                    matchmaker = AllvsAllMatchMaker(type = :plus),
                ),
                parasite_mutualist_avoidant => BasicInteraction(
                    id = parasite_mutualist_avoidant,
                    environment_creator = CollisionGameEnvironmentCreator(
                        domain = CollisionGameDomain(
                            Avoidant()
                        ),
                        initial_distance = initial_distance,
                        episode_length = episode_length
                    ),
                    species_ids = [parasite, host],
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


eco_creator = collision_game_disco_eco_creator(n_pop = 50, n_workers = 1)
eco = evolve!(eco_creator, n_gen=1)
@test length(eco.species) == 3

end
