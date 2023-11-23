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

function run!(
    experiment::BasicExperiment; 
    n_generations::Int = get_n_generations(experiment) 
)
    ecosystem_creator = make_ecosystem_creator(experiment)
    create_archive(ecosystem_creator.archiver, experiment)
    ecosystem = evolve!(ecosystem_creator, n_generations = n_generations)
    return ecosystem
end
