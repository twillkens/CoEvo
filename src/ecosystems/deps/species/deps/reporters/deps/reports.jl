module Reports

export SpeciesStatisticalFeatureSetReport, IndividualStatisticalFeatureSetReport

using .....CoEvo.Abstract: Report, Archiver
using .....CoEvo.Utilities: StatisticalFeatureSet

struct SpeciesStatisticalFeatureSetReport <: Report
    gen::Int
    to_print::Bool
    to_save::Bool
    species_id::String
    cohort::String
    metric::String
    stat_features::StatisticalFeatureSet
    print_features::Vector{Symbol}
    save_features::Vector{Symbol}
end

# Then, for the custom show method:
function Base.show(io::IO, report::SpeciesStatisticalFeatureSetReport)
    println(io, "-----------------------------------------------------------")
    println(io, "Report for Generation: $(report.gen)")
    println(io, "Species ID: $(report.species_id)")
    println(io, "Cohort: $(report.cohort)")
    println(io, "Metric: $(report.metric)")
    
    for feature in report.print_features
        val = getfield(report.stat_features, feature)
        println(io, "    $feature: $val")
    end
end

function(archiver::Archiver)(report::SpeciesStatisticalFeatureSetReport)
    if report.to_print
        Base.show(report)
    end
end

struct IndividualStatisticalFeatureSetReport
    to_print::Bool
    to_save::Bool
    species_id::String
    group_id::String
    indiv_id::Int
    metric::String
    stat_features::StatisticalFeatureSet
    print_features::Vector{Symbol}
    save_features::Vector{Symbol}
end

end