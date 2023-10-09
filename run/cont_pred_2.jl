
include("../src/CoEvo.jl")
using Random: AbstractRNG
using StableRNGs: StableRNG
using .CoEvo
using .Metrics.Concrete.Outcomes.PredictionGameOutcomeMetrics: CooperativeMatching, Competitive
using .Metrics.Concrete.Outcomes.PredictionGameOutcomeMetrics: CooperativeMismatching

function cont_pred_eco_creator(;
    id::String = "ContinuousPredictionGame",
    trial::Int = 1,
    rng::AbstractRNG = StableRNG(42),
    n_pop::Int = 100,
    host::String = "Host",
    mutualist::String = "Mutualist",
    parasite::String = "Parasite",
    interaction_id1::String = "Host-Mutualist-CooperativeMatching",
    interaction_id2::String = "Host-Parasite-Competitive",
    n_elite::Int = 0,
    n_workers::Int = 1,
    episode_length::Int = 16,
    matchmaking_type::Symbol = :comma,
    communication_dimension::Int = 1,
    n_input_nodes::Int = communication_dimension + 2,
    n_output_nodes::Int = communication_dimension + 1,
    n_truncate = 50
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
                    n_input_nodes = n_input_nodes, n_output_nodes = n_output_nodes
                ),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = NSGAIIEvaluator(maximize = true, perform_disco = true, include_parents = false),
                replacer = TruncationReplacer(type = :comma, n_truncate = n_truncate),
                selector = TournamentSelector(μ = n_pop, tournament_size = 3),
                recombiner = CloneRecombiner(),
                mutators = [GnarlNetworkMutator()]
            ),
            mutualist => BasicSpeciesCreator(
                id = mutualist,
                n_pop = n_pop,
                geno_creator = GnarlNetworkGenotypeCreator(
                    n_input_nodes = n_input_nodes, n_output_nodes = n_output_nodes
                ),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = NSGAIIEvaluator(maximize = true, perform_disco = true, include_parents = false),
                replacer = TruncationReplacer(type = :comma, n_truncate = n_truncate),
                selector = TournamentSelector(μ = n_pop, tournament_size = 3),
                recombiner = CloneRecombiner(),
                mutators = [GnarlNetworkMutator()]
            ),
            parasite => BasicSpeciesCreator(
                id = parasite,
                n_pop = n_pop,
                geno_creator = GnarlNetworkGenotypeCreator(
                    n_input_nodes = n_input_nodes, n_output_nodes = n_output_nodes
                ),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = NSGAIIEvaluator(maximize = true, perform_disco = true, include_parents = false),
                replacer = TruncationReplacer(type = :comma, n_truncate = n_truncate),
                selector = TournamentSelector(μ = n_pop, tournament_size = 3),
                recombiner = CloneRecombiner(),
                mutators = [GnarlNetworkMutator()]
            ),
        ),
        job_creator = BasicJobCreator(
            n_workers = 1,
            interactions = Dict(
                interaction_id1 => BasicInteraction(
                    id = interaction_id1,
                    environment_creator = TapeEnvironmentCreator(
                        domain = ContinuousPredictionGameDomain(
                            CooperativeMatching()
                        ),
                        episode_length = episode_length,
                        communication_dimension = communication_dimension
                    ),
                    species_ids = [host, mutualist],
                    matchmaker = AllvsAllMatchMaker(type = matchmaking_type),
                ),
                interaction_id2 => BasicInteraction(
                    id = interaction_id2,
                    environment_creator = TapeEnvironmentCreator(
                        domain = ContinuousPredictionGameDomain(
                            Competitive()
                        ),
                        episode_length = episode_length,
                        communication_dimension = communication_dimension
                    ),
                    species_ids = [parasite, host],
                    matchmaker = AllvsAllMatchMaker(type = matchmaking_type),
                ),
            ),
        ),
        performer = BasicPerformer(n_workers = n_workers),
        reporters = Reporter[
            BasicReporter(metric = GenotypeSize()),
            BasicReporter(metric = GenotypeSize(name = "MinimizedGenotypeSize", minimize = true)),
            BasicReporter(metric = AllSpeciesFitness()),
        ],
        archiver = BasicArchiver(jld2_path = "archive.jld2"),
        runtime_reporter = RuntimeReporter(print_interval = 1),
    )
    return eco_creator
end


eco_creator = cont_pred_eco_creator()
eco = evolve!(eco_creator, n_gen=10_000)



# function cont_pred_eco_creator(;
#     id::String = "Symbolic Regression",
#     trial::Int = 1,
#     rng::AbstractRNG = StableRNG(42),
#     n_pop::Int = 50,
#     host::String = "Host",
#     mutualist::String = "Mutualist",
#     parasite::String = "Parasite",
#     interaction_id1::String = "Host-Mutualist-CooperativeMatching",
#     interaction_id2::String = "Host-Parasite-Competitive",
#     n_elite::Int = 0,
#     n_workers::Int = 1,
#     episode_length::Int = 16
# )
#     eco_creator = BasicEcosystemCreator(
#         id = id,
#         trial = trial,
#         rng = rng,
#         species_creators = Dict(
#             host => BasicSpeciesCreator(
#                 id = host,
#                 n_pop = n_pop,
#                 geno_creator = GnarlNetworkGenotypeCreator(n_input_nodes = n_input_nodes, n_output_nodes = n_output_nodes),
#                 phenotype_creator = DefaultPhenotypeCreator(),
#                 evaluator = NSGAIIEvaluator(),
#                 replacer = TruncationReplacer(:plus),
#                 selector = TournamentSelector(
#                     μ = n_pop, tournament_size = 3, selection_func=argmin
#                 ),
#                 recombiner = CloneRecombiner(),
#                 mutators = [GnarlNetworkMutator()]
#             ),
#             mutualist => BasicSpeciesCreator(
#                 id = mutualist,
#                 n_pop = n_pop,
#                 geno_creator = GnarlNetworkGenotypeCreator(n_input_nodes = n_input_nodes, n_output_nodes = n_output_nodes),
#                 phenotype_creator = DefaultPhenotypeCreator(),
#                 evaluator = NSGAIIEvaluator(),
#                 replacer = TruncationReplacer(:plus),
#                 selector = TournamentSelector(
#                     μ = n_pop, tournament_size = 3, selection_func=argmin
#                 ),
#                 recombiner = CloneRecombiner(),
#                 mutators = [GnarlNetworkMutator()]
#             ),
#             parasite => BasicSpeciesCreator(
#                 id = parasite,
#                 n_pop = n_pop,
#                 geno_creator = GnarlNetworkGenotypeCreator(n_input_nodes = n_input_nodes, n_output_nodes = n_output_nodes),
#                 phenotype_creator = DefaultPhenotypeCreator(),
#                 evaluator = NSGAIIEvaluator(),
#                 replacer = TruncationReplacer(:plus),
#                 selector = TournamentSelector(μ = n_pop, tournament_size = 3),
#                 recombiner = CloneRecombiner(),
#                 mutators = [GnarlNetworkMutator()]
#             ),
#         ),
#         job_creator = BasicJobCreator(
#             n_workers = 1,
#             interactions = Dict(
#                 interaction_id1 => BasicInteraction(
#                     id = interaction_id1,
#                     environment_creator = TapeEnvironmentCreator(
#                         domain = ContinuousPredictionGameDomain(
#                             CooperativeMatching()
#                         ),
#                         episode_length = episode_length 
#                     ),
#                     species_ids = [host, mutualist],
#                     matchmaker = AllvsAllMatchMaker(type = :plus),
#                 ),
#                 interaction_id2 => BasicInteraction(
#                     id = interaction_id2,
#                     environment_creator = TapeEnvironmentCreator(
#                         domain = ContinuousPredictionGameDomain(
#                             Competitive()
#                         ),
#                         episode_length = episode_length
#                     ),
#                     species_ids = [parasite, host],
#                     matchmaker = AllvsAllMatchMaker(type = :plus),
#                 ),
#             ),
#         ),
#         performer = BasicPerformer(n_workers = n_workers),
#         reporters = Reporter[
#             BasicReporter(metric = GenotypeSize()),
#             BasicReporter(metric = AllSpeciesFitness()),
#         ],
#         archiver = BasicArchiver(),
#         runtime_reporter = RuntimeReporter(print_interval = 1),
#     )
#     return eco_creator
# end
# 
# 
# eco_creator = cont_pred_eco_creator(n_pop = 50, n_workers = 1)
# eco = evolve!(eco_creator, n_gen=5_000)
# #
# #
# #