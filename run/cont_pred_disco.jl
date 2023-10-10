using Distributed
include("../src/CoEvo.jl")
using .CoEvo


@everywhere begin

include("../src/CoEvo.jl")
using .CoEvo
using Distributed
using Random: AbstractRNG
using StableRNGs: StableRNG
using .Metrics.Concrete.Outcomes: PredictionGameOutcomeMetrics
using .PredictionGameOutcomeMetrics: CooperativeMatching, Competitive
using .PredictionGameOutcomeMetrics: CooperativeMismatching, Control
using .Metrics.Concrete.Common: AllSpeciesIdentity
using .Mutators.Types: GnarlNetworkMutator

function cont_pred_eco_creator(;
    id::String = "ContinuousPredictionGame",
    trial::Int = 1,
    rng::AbstractRNG = StableRNG(69),
    n_pop::Int = 50,
    host::String = "Host",
    mutualist::String = "Mutualist",
    parasite::String = "Parasite",
    interaction_id1::String = "Host-Mutualist-CooperativeMatching",
    interaction_id2::String = "Host-Parasite-Competitive",
    n_elite::Int = 0,
    n_workers::Int = 1,
    episode_length::Int = 32,
    matchmaking_type::Symbol = :plus,
    communication_dimension::Int = 2,
    n_input_nodes::Int = communication_dimension + 2,
    n_output_nodes::Int = communication_dimension + 1,
    n_truncate = 50,
    tournament_size::Int = 3,
    max_clusters::Int = 10,
    mutator::GnarlNetworkMutator = GnarlNetworkMutator(probs = Dict(
        :add_node => 1/8,
        :add_connection => 1/8,
        :remove_node => 1/8,
        # :remove_node_2 => 1/16,
        :remove_connection => 1/8,
        :identity_mutation => 1/2
    ))
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
                geno_creator = GnarlNetworkGenotypeCreator(
                    n_input_nodes = n_input_nodes, n_output_nodes = n_output_nodes
                ),
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
                geno_creator = GnarlNetworkGenotypeCreator(
                    n_input_nodes = n_input_nodes, n_output_nodes = n_output_nodes
                ),
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
                "c" => BasicInteraction(
                    id = "c",
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
            BasicReporter(metric = GenotypeSize(), save_interval = 1, print_interval = 50),
            BasicReporter(
                metric = GenotypeSize(name = "MinimizedGenotypeSize", minimize = true),
                save_interval = 1, print_interval = 50
            ),
            BasicReporter(metric = AllSpeciesFitness(), save_interval = 1, print_interval = 50),
            BasicReporter(metric = AllSpeciesIdentity(), save_interval = 1, print_interval = 50),
        ],
        archiver = BasicArchiver(jld2_path = "$id.jld2"),
        runtime_reporter = RuntimeReporter(print_interval = 50),
    )
    return eco_creator
end


# Function to display the loading interface
@everywhere function load_interface(trial::Int, action::String)
    println("Trial $trial: $action ...")
end

# The evolve function with added print statements
@everywhere function evolve_trial(trial::Int, id::String = "eco", n_gen::Int = 25_000)
    load_interface(trial, "Starting")
    
    eco_creator = cont_pred_eco_creator(trial=trial, id = "$id-$trial")
    eco = evolve!(eco_creator, n_gen = n_gen)
    
    load_interface(trial, "Completed")
    return eco
end

end


# Run experiments in parallel
function run_parallel_experiments(n_trials::Int = 10, id::String = "eco", n_gen::Int = 25_000)
    # Check number of available workers
    n_workers = nprocs()
    #if n_workers == 1
    #    # Add workers if only one (main process) is available
    #    addprocs(n_trials)
    #end

    # Parallel map over the number of trials
    results = pmap(trial -> evolve_trial(trial, id, n_gen), 1:n_trials)

    # Clean up workers if they were added before
    if n_workers == 1
        rmprocs(workers())
    end

    return results
end

# User interface to start the experiments
function start_experiments()
    println("Welcome to CoEvo!")
    println("What is the name of the experiment?")
    id = readline()
    println("How many trials would you like to run in parallel?")
    n_trials = parse(Int, readline())
    println("How many generations?")
    n_generations = parse(Int, readline())
    results = run_parallel_experiments(n_trials, id, n_generations)
    println("All trials completed!")
    return results
end

# Now, to run the experiments, just call:
# results = start_experiments()
#
#
#function run(id::String = "eco", n_gen::Int = 25_000) 
#    eco_creator = cont_pred_eco_creator()
#    eco = evolve!(eco_creator, n_gen = n_gen, id = id)
#    return eco
#end
