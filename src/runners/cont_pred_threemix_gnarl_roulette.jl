module ContinuousPredictionGameThreeMixGnarlRoulette

export cont_pred_threemix_gnarl_roulette_eco_creator

using Distributed
using Random: AbstractRNG
using StableRNGs: StableRNG
using ...Metrics.Concrete.Outcomes: PredictionGameOutcomeMetrics
using .PredictionGameOutcomeMetrics: CooperativeMatching, Competitive
using .PredictionGameOutcomeMetrics: CooperativeMismatching, Control
using ...Metrics.Concrete.Common: AllSpeciesIdentity
using ...Species.Mutators.Types: GnarlNetworkMutator
using ...Species.Genotypes.GnarlNetworks: GnarlNetworkGenotypeCreator
using ...Species.Phenotypes.Defaults: DefaultPhenotypeCreator
using ...Evaluators.Types.ScalarFitness: ScalarFitnessEvaluator
using ...Replacers.Types.Truncation: TruncationReplacer
using ...Selectors.Types.FitnessProportionate: FitnessProportionateSelector
using ...Species.Basic: BasicSpeciesCreator
using ...Ecosystems.Basic: BasicEcosystemCreator
using ...Recombiners.Types.Clone: CloneRecombiner
using ...Jobs.Basic: BasicJobCreator

using ...Ecosystems.Interactions.Concrete.Basic: BasicInteraction
using ...Environments.Concrete.Tape: ContinuousPredictionGameEnvironmentCreatorr
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

function cont_pred_threemix_gnarl_roulette_eco_creator(;
    id::String = "ContinuousPredictionGameThreeMixGnarlRoulette",
    trial::Int = 1,
    random_number_generator::AbstractRNG = StableRNG(777),
    n_population::Int = 100,
    host::String = "Host",
    mutualist::String = "Mutualist",
    parasite::String = "Parasite",
    interaction_id_1::String = "Host-Mutualist-CooperativeMatching",
    interaction_id_2::String = "Host-Parasite-Competitive",
    interaction_id_3::String = "Parasite-Mutualist-CooperativeMismatching",
    n_elite::Int = 0,
    n_workers::Int = 1,
    episode_length::Int = 32,
    matchmaking_type::Symbol = :plus,
    communication_dimension::Int = 2,
    n_input_nodes::Int = communication_dimension + 2,
    n_output_nodes::Int = communication_dimension + 1,
    n_truncate = 100,
    tournament_size::Int = 3,
    max_clusters::Int = 10,
    mutator::GnarlNetworkMutator = GnarlNetworkMutator(probs = Dict(
        :add_node => 1/8,
        :add_connection => 1/8,
        :remove_node => 1/8,
        :remove_connection => 1/8,
        :identity_mutation => 1/2
    ))
)
    ecosystem_creator = BasicEcosystemCreator(
        id = id,
        trial = trial,
        random_number_generator = random_number_generator,
        species_creators = Dict(
            host => BasicSpeciesCreator(
                id = host,
                n_population = n_population,
                genotype_creator = GnarlNetworkGenotypeCreator(
                    n_input_nodes = n_input_nodes, n_output_nodes = n_output_nodes
                ),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = ScalarFitnessEvaluator(),
                replacer = TruncationReplacer(type = matchmaking_type, n_truncate = n_truncate),
                selector = FitnessProportionateSelector(n_parents = n_population),
                recombiner = CloneRecombiner(),
                mutators = [mutator]
            ),
            mutualist => BasicSpeciesCreator(
                id = mutualist,
                n_population = n_population,
                genotype_creator = GnarlNetworkGenotypeCreator(
                    n_input_nodes = n_input_nodes, n_output_nodes = n_output_nodes
                ),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = ScalarFitnessEvaluator(),
                replacer = TruncationReplacer(type = matchmaking_type, n_truncate = n_truncate),
                selector = FitnessProportionateSelector(n_parents = n_population),
                recombiner = CloneRecombiner(),
                mutators = [mutator]
            ),
            parasite => BasicSpeciesCreator(
                id = parasite,
                n_population = n_population,
                genotype_creator = GnarlNetworkGenotypeCreator(
                    n_input_nodes = n_input_nodes, n_output_nodes = n_output_nodes
                ),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = ScalarFitnessEvaluator(),
                replacer = TruncationReplacer(type = matchmaking_type, n_truncate = n_truncate),
                selector = FitnessProportionateSelector(n_parents = n_population),
                recombiner = CloneRecombiner(),
                mutators = [mutator]
            ),
        ),
        job_creator = BasicJobCreator(
            n_workers = 1,
            interactions = Dict(
                interaction_id_1 => BasicInteraction(
                    id = interaction_id_1,
                    environment_creator = ContinuousPredictionGameEnvironmentCreatorr(
                        domain = ContinuousPredictionGameDomain(
                            CooperativeMatching()
                        ),
                        episode_length = episode_length,
                        communication_dimension = communication_dimension
                    ),
                    species_ids = [host, mutualist],
                    matchmaker = AllvsAllMatchMaker(type = matchmaking_type),
                ),
                interaction_id_2 => BasicInteraction(
                    id = interaction_id_2,
                    environment_creator = ContinuousPredictionGameEnvironmentCreatorr(
                        domain = ContinuousPredictionGameDomain(
                            Competitive()
                        ),
                        episode_length = episode_length,
                        communication_dimension = communication_dimension
                    ),
                    species_ids = [parasite, host],
                    matchmaker = AllvsAllMatchMaker(type = matchmaking_type),
                ),
                interaction_id_3 => BasicInteraction(
                    id = interaction_id_3,
                    environment_creator = ContinuousPredictionGameEnvironmentCreatorr(
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
            BasicReporter(metric = GenotypeSize(), save_interval = 1, print_interval = 25),
            BasicReporter(
                metric = GenotypeSize(name = "MinimizedGenotypeSize", minimize = true),
                save_interval = 1, print_interval = 25
            ),
            BasicReporter(metric = AllSpeciesFitness(), save_interval = 1, print_interval = 25),
            BasicReporter(metric = AllSpeciesIdentity(), save_interval = 1, print_interval = 25),
        ],
        archiver = BasicArchiver(jld2_path = "trials/$id/$trial.jld2"),
        runtime_reporter = RuntimeReporter(print_interval = 25),
    )
    return ecosystem_creator
end

end