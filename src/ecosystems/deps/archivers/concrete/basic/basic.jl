module Basic

export BasicArchiver

using DataStructures: OrderedDict
using JLD2: JLDFile, Group, jldopen

using ...Utilities: get_or_make_group!

using ...Archivers.Abstract: Archiver
using ....Reporters.Abstract: Report
using ....Reporters.Types.Basic: BasicReport
using ....Reporters.Types.Runtime: RuntimeReport
using ....Metrics.Concrete.Evaluations: AllSpeciesFitness
using ....Metrics.Concrete.Genotypes: GenotypeSum, GenotypeSize
using ....Metrics.Concrete.Common: AbsoluteError
using ....Measurements: GroupStatisticalMeasurement, BasicStatisticalMeasurement

import ...Archivers.Interfaces: archive!


Base.@kwdef struct BasicArchiver <: Archiver 
    jld2_path::String = "archive.jld2"
end


#function archive!(archiver::BasicArchiver, gen::Int, report::Report)
#    println("Archiving generation $gen")
#    println("Report: $report")
#end
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

function archive!(
    ::BasicArchiver, 
    gen::Int, 
    report::BasicReport{GenotypeSum, GroupStatisticalMeasurement}
)
    for (species_id, measurement) in report.measurement.measurements
        println("----")
        println("Sum for species ", species_id)
        println("Mean: ", measurement.mean)
        #println("Min: ", measurement.minimum)
        #println("Max: ", measurement.maximum)
        #println("Std: ", measurement.std)
    end
end

function archive!(
    ::BasicArchiver, 
    gen::Int, 
    report::BasicReport{GenotypeSize, GroupStatisticalMeasurement}
)
    for (species_id, measurement) in report.measurement.measurements
        println("----")
        println("Root tree size for species ", species_id)
        println("Mean: ", measurement.mean)
        println("Min: ", measurement.minimum)
        println("Max: ", measurement.maximum)
        println("Std: ", measurement.std)
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
function archive!(
    ::BasicArchiver, 
    gen::Int, 
    report::BasicReport{AllSpeciesFitness, GroupStatisticalMeasurement}
)
    for (species_id, measurement) in report.measurement.measurements
        println("----")
        println("Fitness for species ", species_id)
        println("Mean: ", measurement.mean)
        #println("Min: ", measurement.minimum)
        #println("Max: ", measurement.maximum)
        #println("Std: ", measurement.std)
    end
end

using ...Archivers.Interfaces: save_genotype!
using ....Species.Individuals: Individual
using ...Archivers.Utilities: get_or_make_group!
# # Save an individual to a JLD2.Group
function save_individual!(
    archiver::BasicArchiver, indiv_group::Group, indiv::Individual
)
    indiv_group["parent_ids"] = indiv.parent_ids
    geno_group = Group(indiv_group, "genotype")
    save_genotype!(archiver, geno_group, indiv.geno)
end
using ....Metrics.Concrete.Common: AllSpeciesIdentity
using ....Measurements.Types: AllSpeciesMeasurement
using ....Reporters.Types.Basic: BasicReport

function archive!(
    archiver::BasicArchiver, 
    gen::Int, 
    report::BasicReport{AllSpeciesIdentity, AllSpeciesMeasurement}
)
    jld2_file = jldopen(archiver.jld2_path, "r+")
    base_path = "indivs/$gen"
    for (species_id, species) in report.species
        individuals = gen == 1 ? species.pop : species.children
        species_path = "$base_path/$species_id/"
        for individual in individuals
            individual_path = "$species_path/$(individual.id)"
            individual_group = get_or_make_group!(jld2_file, individual_path)
            save_individual!(archiver, individual_group, individual)
        end
    end
    close(jld2_file)
end

end