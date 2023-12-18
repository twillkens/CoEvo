export EcosystemCheckpoint, run!, make_ecosystem_creator

using ...Archivers.Basic: BasicArchiver
using ...Ecosystems: Ecosystem, create_ecosystem

struct EcosystemCheckpoint{E <: Ecosystem}
    generation::Int
    ecosystem::E
    globals::GlobalConfiguration
end

function EcosystemCheckpoint(file::File)
    generations = sort(parse.(Int, keys(file["generations"])), rev = true)
    for gen in generations
        println("Loading generation $gen")
        try
            ecosystem = load_ecosystem(file, gen)
            globals = load_globals(file, gen)
            return EcosystemCheckpoint(gen, ecosystem, globals)
        catch e
            println(e)
            continue
        end
    end
    throw(ErrorException("No ecosystem found in $file"))
end

function EcosystemCheckpoint(archive_path::String)
    file = h5open(archive_path, "r")
    ecosystem = EcosystemCheckpoint(file)
    close(file)
    return ecosystem
end

function EcosystemCheckpoint(archiver::BasicArchiver)
    ecosystem = EcosystemCheckpoint(archiver.archive_path)
    return ecosystem
end

EcosystemCheckpoint(ecosystem_creator::BasicEcosystemCreator) = 
    EcosystemCheckpoint(ecosystem_creator.archiver)

create_archive(ecosystem_creator::BasicEcosystemCreator, experiment::BasicExperiment) = 
    create_archive(ecosystem_creator.archiver, experiment)

does_archive_exist(ecosystem_creator::BasicEcosystemCreator) = 
    isfile(ecosystem_creator.archiver.archive_path)

function run!(
    experiment::BasicExperiment; 
    n_generations::Int = get_n_generations(experiment) 
)
    ecosystem_creator = make_ecosystem_creator(experiment)
    archive_exists = does_archive_exist(ecosystem_creator)
    if archive_exists
        checkpoint = EcosystemCheckpoint(ecosystem_creator)
        rng_state = parse(UInt128, checkpoint.globals.rng_state_string)
        rng = StableRNG(state = rng_state)
        ecosystem_creator.rng = rng
        ecosystem_creator.individual_id_counter.current_value = checkpoint.globals.individual_id_counter_state
        ecosystem_creator.gene_id_counter.current_value = checkpoint.globals.gene_id_counter_state
        ecosystem = checkpoint.ecosystem
        generations = UnitRange(checkpoint.generation + 1, n_generations)
    else
        create_archive(ecosystem_creator.archiver, experiment)
        ecosystem = create_ecosystem(ecosystem_creator)
        generations = UnitRange(1, n_generations)
    end
    ecosystem = evolve!(ecosystem_creator, ecosystem, generations)
    return ecosystem
end

function run!(;
    game::String = "continuous_prediction_game",
    topology::String = "two_control",
    substrate::String = "function_graphs",
    reproducer::String = "disco",
    report::String = "silent",
    kwargs...
)
    experiment = make_prediction_game_experiment(;
        game = game,
        topology = topology,
        substrate = substrate,
        reproducer = reproducer,
        report = report,
        kwargs...
    )
    ecosystem = run!(experiment)
    return ecosystem
end