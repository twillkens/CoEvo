module Reports

export CohortMetricReport

using .....CoEvo.Abstract: Report, Archiver
using .....CoEvo.Utilities.Statistics: StatisticalFeatureSet

struct CohortMetricReport <: Report
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
function Base.show(io::IO, report::CohortMetricReport)
    println(io, "-----------------------------------------------------------")
    println(io, "Generation $(report.gen)")
    println(io, "Species ID: $(report.species_id)")
    println(io, "Cohort: $(report.cohort)")
    println(io, "Metric: $(report.metric)")
    
    for feature in report.print_features
        val = getfield(report.stat_features, feature)
        println(io, "    $feature: $val")
    end
end

function(archiver::Archiver)(report::CohortMetricReport)
    if report.to_print
        Base.show(report)
    end
end

end