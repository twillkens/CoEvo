Base.@kwdef struct BasicArchiver <: Archiver 
    archive_path::String = "archive.jld2"
end

function archive!(
    ::BasicArchiver, 
    gen::Int, 
    report::RuntimeReport
)
    if report.to_print
        println("-----------------------------------------------------------")
        println("Generation: $gen")
        println("Evaluation time: $(report.eval_time)")
        println("Reproduction time: $(report.reproduce_time)")
    end
end

function save_measurement!(group::Group, measurement::BasicStatisticalMeasurement)
    group["sum"] = measurement.sum
    group["upper_confidence"] = measurement.upper_confidence
    group["mean"] = measurement.mean
    group["lower_confidence"] = measurement.lower_confidence
    group["variance"] = measurement.variance
    group["std"] = measurement.std
    group["minimum"] = measurement.minimum
    group["lower_quartile"] = measurement.lower_quartile
    group["median"] = measurement.median
    group["upper_quartile"] = measurement.upper_quartile
    group["maximum"] = measurement.maximum
    group["skew"] = measurement.skew
    group["kurt"] = measurement.kurt
    group["mode"] = measurement.mode
end

function archive!(
    archiver::BasicArchiver, 
    gen::Int, 
    report::BasicReport{<:Metric, GroupStatisticalMeasurement}
)
    if report.to_print
        for (species_id, measurement) in sort(collect(report.measurement.measurements), by = x -> x[1])
            println("---$(report.metric.name): $species_id---")
            println("Mean: $(measurement.mean), Min: $(measurement.minimum), Max: $(measurement.maximum), Std: $(measurement.std)", )
        end
    end
    if report.to_save
        jld2_file = jldopen(archiver.archive_path, "a+")
        base_path = "measurements/$gen/$(report.metric.name)"
        
        # Create or access the group for the generation
        gen_group = get_or_make_group!(jld2_file, base_path)
        
        for (species_id, measurement) in report.measurement.measurements
            species_group = get_or_make_group!(gen_group, species_id)
            save_measurement!(species_group, measurement)
        end
        
        close(jld2_file)
    end
end


function archive!(
    ::BasicArchiver, 
    gen::Int, 
    report::BasicReport{AbsoluteError, BasicStatisticalMeasurement}
)
    measurement = report.measurement
    println("----")
    println("AbsoluteError")
    println("Min: ", measurement.minimum)
    println("Mean: ", measurement.mean)
    println("Max: ", measurement.maximum)
end

# # Save an individual to a JLD2.Group
function save_individual!(
    archiver::BasicArchiver, indiv_group::Group, individual::Individual
)
    indiv_group["parent_ids"] = individual.parent_ids
    geno_group = Group(indiv_group, "genotype")
    save_genotype!(archiver, geno_group, individual.genotype)
end

function archive!(
    archiver::BasicArchiver, 
    gen::Int, 
    report::BasicReport{<:AllSpeciesIdentity, <:AllSpeciesMeasurement}
)
    if report.to_save
        jld2_file = jldopen(archiver.archive_path, "a+")
        base_path = "individuals/$gen"
        #println("base_path: $base_path")
        for (species_id, species) in report.measurement.species
            individuals = gen == 1 ? species.population : species.children
            species_path = "$base_path/$species_id"
            species_group = get_or_make_group!(jld2_file, species_path)
            species_group["population_ids"] = [
                individual.id for individual in species.population
            ]
            #println("species_path: $species_path")
            for individual in individuals
                individual_id = string(individual.id)
                individual_path = "$species_path/children/$individual_id"
                #println("individual_path: $individual_path")
                individual_group = get_or_make_group!(jld2_file, individual_path)
                save_individual!(archiver, individual_group, individual)
            end
        end
        close(jld2_file)
    end
end