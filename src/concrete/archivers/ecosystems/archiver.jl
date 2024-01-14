
#struct MigrationArchiver <: Archiver
#    archive_interval::Int
#    archive_directory::String
#end

#using ....Abstract.States: get_all_species, get_evaluations
#
#function archive!(archiver::MigrationArchiver, state::State)
#    do_not_archive = archiver.archive_interval == 0 || get_generation(state) == 1
#    is_archive_interval = (get_generation(state) + 1) % archiver.archive_interval == 0
#    #println(get_generation(state), is_archive_interval)
#    if do_not_archive || !is_archive_interval
#        return
#    end
#    generation = get_generation(state)
#    #println("archiving generation $generation")
#    archive_path = "$(archiver.archive_directory)/generations/$generation.h5"
#    file = h5open(archive_path, "w")
#    for (species, evaluation) in zip(get_all_species(state), get_evaluations(state))
#        migration_ids = [record.id for record in evaluation.records[1:5]]
#        summaries = [(record.id, record.rank, record.crowding) for record in evaluation.records[1:5]]
#        println("archiving migration individuals: $summaries")
#        migration_individuals = [
#            individual for individual in get_population(species) 
#            if individual.id in migration_ids
#        ]
#        for individual in migration_individuals
#            individual_path = "$(species.id)/$(individual.id)"
#            archive!(file, individual_path, individual)
#        end
#    end
#    file["valid"] = true
#    close(file)
#    flush(stdout)
#end