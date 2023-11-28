export make_ecosystem_id, make_ecosystem_creator

using ...Names: BasicEcosystemCreator

function make_ecosystem_id(
    game::GameConfiguration, 
    topology::Topology, 
    substrate::Substrate, 
    reproducer::Reproducer, 
    globals::GlobalConfiguration
)
    id = joinpath(string.([game.id, topology.id, substrate.id, reproducer.id, globals.trial]))
    return id
end

function make_ecosystem_creator(
    globals::GlobalConfiguration, 
    game::GameConfiguration,
    topology::Topology,
    substrate::Substrate, 
    reproducer::Reproducer,
    report::ReportConfiguration
)
    ecosystem_creator = BasicEcosystemCreator(
        id = make_ecosystem_id(game, topology, substrate, reproducer, globals),
        trial = get_trial(globals),
        random_number_generator = make_random_number_generator(globals),
        species_creators = make_species_creators(topology, substrate, reproducer, game),
        job_creator = make_job_creator(globals, game, topology), 
        performer = make_performer(globals),
        state_creator = make_state_creator(globals),
        reporters = make_reporters(report),
        archiver = make_archiver(game, topology, substrate, reproducer, globals),
        individual_id_counter = make_individual_id_counter(globals),
        gene_id_counter = make_gene_id_counter(globals),
    )
    return ecosystem_creator
end
