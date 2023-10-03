module Report

using DataStructures: OrderedDict
using ..Species.Abstract: SpeciesReporter

using ....Ecosystems.Metrics.Species.Abstract: SpeciesMetric

import ...Interfaces: create_reports


function create_reports(
    reporter::SpeciesReporter{<:SpeciesMetric},
    gen::Int,
    to_print::Bool,
    to_save::Bool,
    all_species::Dict{String, AbstractSpecies},
    all_evaluations::Dict{String, Evaluation},
    ::Vector{Observation},
)
    reports = Report[]
    for (species_id, species) in all_species
        evaluation = all_evaluations[species_id]
        measure_set = measure(reporter, species, evaluation)
        report = BasicSpeciesReport(
            gen,
            to_print,
            to_save,
            species_id,
            reporter.metric,
            measure_set,
            reporter.print_measures,
            reporter.save_measures
        )
        push!(reports, report)
    end

    return reports
end

end