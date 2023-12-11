export run!, get_n_generations, make_ecosystem_creator, BasicExperiment

using ...Names
using ..Configurations: evolve!

struct BasicExperiment{
    G1 <: GlobalConfiguration,
    G2 <: GameConfiguration, 
    T <: Topology, 
    S <: Substrate, 
    R1 <: Reproducer, 
    R2 <: ReportConfiguration,
}
    globals::G1
    game::G2
    topology::T
    substrate::S
    reproducer::R1
    report::R2
end

function make_ecosystem_creator(experiment::BasicExperiment)
    ecosystem_creator = make_ecosystem_creator(
        experiment.globals, 
        experiment.game, 
        experiment.topology, 
        experiment.substrate, 
        experiment.reproducer,
        experiment.report
    )
    return ecosystem_creator
end

get_n_generations(
    configuration::BasicExperiment
) = get_n_generations(configuration.globals)


create_archive(
    archiver::BasicArchiver,
    experiment::BasicExperiment
) = create_archive(
    archiver.archive_path,
    experiment.globals,
    experiment.game,
    experiment.topology,
    experiment.substrate,
    experiment.reproducer,
    experiment.report,
)

function make_prediction_game_experiment(;
    game::String = "continuous_prediction_game",
    topology::String = "two_control",
    substrate::String = "function_graphs",
    reproducer::String = "disco",
    report::String = "silent",
    kwargs...
)
    globals = GlobalConfiguration(; kwargs...)
    game = get_game(game; kwargs...)
    topology = get_topology(topology; kwargs...)
    substrate = get_substrate(substrate; kwargs...)
    reproducer = get_reproducer(reproducer; kwargs...)
    report = get_report(report; kwargs...)
    experiment = BasicExperiment(
        globals, game, topology, substrate, reproducer, report
    )
    return experiment
end
