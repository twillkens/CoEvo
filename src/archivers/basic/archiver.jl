Base.@kwdef struct BasicArchiver <: Archiver 
    archive_path::String = "archive.h5"
end

function archive!(archiver::Archiver, measurement::BasicMeasurement, group::Group)
    group["value"] = measurement.value
end

function archive!(::BasicArchiver, report::RuntimeReport)
    if report.to_print
        println("-----------------------------------------------------------")
        println("Generation: $(report.generation)")
        println("Evaluation time: $(report.eval_time)")
        println("Reproduction time: $(report.reproduce_time)")
    end
end

function archive!(archiver::BasicArchiver, individual::BasicIndividual, group::Group)
    group["parent_ids"] = individual.parent_ids
    genotype_group = Group(group, "genotype")
    archive!(archiver, genotype_group, individual.genotype)
end

function archive!(archiver::BasicArchiver, species::BasicSpecies, group::Group)
    population_ids = [individual.id for individual in species.population]
    group["population_ids"] = population_ids
    for child in species.children
        child_id = string(child.id)
        child_group = Group(group, "children/$child_id")
        archive!(archiver, child_group, child)
    end
end

function archive!(archiver::BasicArchiver, measurement::SaveAllSpeciesMeasurement, group::Group)
    for species in measurement.all_species
        species_id = species.id
        species_group = Group(group, "species/$species_id")
        archive!(archiver, species, species_group)
    end
end

function archive!(archiver::BasicArchiver, measurement::GroupMeasurement, group::Group)
    for (name, sub_measurement) in measurement.measurements
        sub_group = Group(group, name)
        archive!(archiver, sub_measurement, sub_group)
    end
end

function archive!(archiver::BasicArchiver, report::Report)
    if report.to_save
        h5_file = h5open(archiver.archive_path, "r+")
        base_path = "generations/$(report.generation)/$(report.measurement.id)"
        group = get_or_make_group!(h5_file, base_path)
        archive!(archiver, report.measurement, group)
        close(h5_file)
    end
end