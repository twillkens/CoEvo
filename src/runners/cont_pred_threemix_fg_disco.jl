module ContinuousPredictionGameThreeMixFunctionGraphsDisco

export cont_pred_threemix_function_graphs_disco_eco_creator

using Distributed
using Random: AbstractRNG
using StableRNGs: StableRNG
using ...Metrics.Concrete.Outcomes: PredictionGameOutcomeMetrics
using .PredictionGameOutcomeMetrics: CooperativeMatching, Competitive
using .PredictionGameOutcomeMetrics: CooperativeMismatching, Control
using ...Metrics.Concrete.Common: AllSpeciesIdentity
using ...Species.Mutators.Types: FunctionGraphMutator
using ...Species.Genotypes.GnarlNetworks: GnarlNetworkGenotypeCreator
using ...Species.Genotypes.FunctionGraphs: FunctionGraphGenotypeCreator
using ...Species.Phenotypes.Defaults: DefaultPhenotypeCreator
using ...Evaluators.Types.NSGAII: NSGAIIEvaluator
using ...Replacers.Types.Truncation: TruncationReplacer
using ...Species.Basic: BasicSpeciesCreator
using ...Ecosystems.Basic: BasicEcosystemCreator
using ...Selectors.Types.Tournament: TournamentSelector
using ...Recombiners.Types.Clone: CloneRecombiner
using ...Jobs.Basic: BasicJobCreator

using ...Ecosystems.Interactions.Concrete.Basic: BasicInteraction
using ...Environments.Concrete.Tape: TapeEnvironmentCreator
using ...Domains.Concrete.ContinuousPredictionGame: ContinuousPredictionGameDomain
using ...MatchMakers.AllvsAll: AllvsAllMatchMaker
using ...Performers.Concrete.Cache: CachePerformer
using ...Reporters.Types.Basic: BasicReporter
using ...Reporters.Types.Runtime: RuntimeReporter
using ...Reporters.Abstract: Reporter

using ...Metrics.Concrete.Genotypes: GenotypeSize
using ...Metrics.Concrete.Evaluations: AllSpeciesFitness
using ...Archivers.Concrete.Basic: BasicArchiver
using ...Ecosystems.Interfaces: evolve!

function cont_pred_threemix_function_graphs_disco_eco_creator(;
    id::String = "ContinuousPredictionGame",
    trial::Int = 1,
    rng::AbstractRNG = StableRNG(777),
    n_pop::Int = 50,
    host::String = "Host",
    mutualist::String = "Mutualist",
    parasite::String = "Parasite",
    interaction_id1::String = "Host-Mutualist-Affinitive",
    interaction_id2::String = "Host-Parasite-Adversarial",
    interaction_id3::String = "Mutualist-Parasite-Avoidant",
    n_workers::Int = 1,
    episode_length::Int = 32,
    matchmaking_type::Symbol = :plus,
    communication_dimension::Int = 2,
    n_input_nodes::Int = communication_dimension + 2,
    n_bias_nodes::Int = 1,
    n_output_nodes::Int = communication_dimension + 1,
    n_truncate = 50,
    tournament_size::Int = 3,
    max_clusters::Int = -1,
    geno_creator::FunctionGraphGenotypeCreator = FunctionGraphGenotypeCreator(
        n_input_nodes = n_input_nodes, 
        n_bias_nodes = n_bias_nodes,
        n_output_nodes = n_output_nodes
    ),
    mutator::FunctionGraphMutator = FunctionGraphMutator(),
    print_interval::Int = 1,
    save_interval::Int = 0,
)
    eco_creator = BasicEcosystemCreator(
        id = id,
        trial = trial,
        rng = rng,
        species_creators = Dict(
            host => BasicSpeciesCreator(
                id = host,
                n_pop = n_pop,
                geno_creator = geno_creator,
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = NSGAIIEvaluator(
                    max_clusters = max_clusters, 
                    maximize = true, 
                    perform_disco = true, 
                    include_parents = true
                ),
                replacer = TruncationReplacer(type = matchmaking_type, n_truncate = n_truncate),
                selector = TournamentSelector(μ = n_pop, tournament_size = tournament_size),
                recombiner = CloneRecombiner(),
                mutators = [mutator]
            ),
            mutualist => BasicSpeciesCreator(
                id = mutualist,
                n_pop = n_pop,
                geno_creator = geno_creator,
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = NSGAIIEvaluator(
                    max_clusters = max_clusters, 
                    maximize = true, 
                    perform_disco = true, 
                    include_parents = true
                ),
                replacer = TruncationReplacer(type = matchmaking_type, n_truncate = n_truncate),
                selector = TournamentSelector(μ = n_pop, tournament_size = tournament_size),
                recombiner = CloneRecombiner(),
                mutators = [mutator]
            ),
            parasite => BasicSpeciesCreator(
                id = parasite,
                n_pop = n_pop,
                geno_creator = geno_creator,
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = NSGAIIEvaluator(
                    max_clusters = max_clusters, 
                    maximize = true, 
                    perform_disco = true, 
                    include_parents = true
                ),
                replacer = TruncationReplacer(type = matchmaking_type, n_truncate = n_truncate),
                selector = TournamentSelector(μ = n_pop, tournament_size = tournament_size),
                recombiner = CloneRecombiner(),
                mutators = [mutator]
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
                interaction_id3 => BasicInteraction(
                    id = interaction_id3, 
                    environment_creator = TapeEnvironmentCreator(
                        domain = ContinuousPredictionGameDomain(
                            CooperativeMismatching()
                        ),
                        episode_length = episode_length,
                        communication_dimension = communication_dimension
                    ),
                    species_ids = [parasite, mutualist],
                    matchmaker = AllvsAllMatchMaker(type = matchmaking_type),
                ),
            ),
        ),
        performer = CachePerformer(n_workers = n_workers),
        reporters = Reporter[
            BasicReporter(
                metric = GenotypeSize(), 
                save_interval = save_interval, 
                print_interval = print_interval
            ),
            BasicReporter(
                metric = GenotypeSize(name = "MinimizedGenotypeSize", minimize = true),
                save_interval = save_interval,
                print_interval = print_interval
            ),
            BasicReporter(
                metric = AllSpeciesFitness(), 
                save_interval = save_interval, 
                print_interval = print_interval
            ),
            #BasicReporter(metric = AllSpeciesIdentity(), save_interval = 1, print_interval = 50),
        ],
        archiver = BasicArchiver(jld2_path = "trials/$id/$trial.jld2"),
        runtime_reporter = RuntimeReporter(print_interval = print_interval),
    )
    return eco_creator
end


end