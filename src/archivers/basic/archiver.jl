Base.@kwdef struct BasicArchiver <: Archiver 
    archive_path::String = "archive.h5"
end

function archive!(::BasicArchiver, ::NullReport)
    return
end

function archive!(::BasicArchiver, report::BasicReport{RuntimeMetric, <:BasicMeasurement})
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

function archive!(archiver::BasicArchiver, measurement::SnapshotSpeciesMeasurement, group::Group)
    for species in measurement.all_species
        species_id = species.id
        species_group = Group(group, "species/$species_id")
        archive!(archiver, species, species_group)
    end
end
