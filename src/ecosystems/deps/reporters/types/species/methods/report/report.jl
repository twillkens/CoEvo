module Report

using DataStructures: OrderedDict
using ..Species.Abstract: SpeciesReporter

using ....Ecosystems.Metrics.Species.Genotype.Abstract: GenotypeMetric
using ....Ecosystems.Metrics.Species.Evaluation.Abstract: EvaluationMetric
using ....Ecosystems.Metrics.Species.Individual.Abstract: IndividualMetric
using ....Ecosystems.Metrics.Species.Abstract: SpeciesMetric

import ...Interfaces: create_reports

function create_report(
    reporter::SpeciesReporter{<:IndividualMetric}, 
    species::Dict{String, AbstractSpecies}
    evaluations::Dict{String, Evaluation}
)
    genotypes = [indiv.geno for indiv in keys(indiv_evals)]
    report = create_report(reporter, genotypes)

    return report
end
function create_report(
    reporter::SpeciesReporter{<:GenotypeMetric}, 
    indiv_evals::OrderedDict{<:Individual, <:Evaluation}
)
    genotypes = [indiv.geno for indiv in keys(indiv_evals)]
    report = create_report(reporter, genotypes)

    return report
end

function create_report(
    reporter::SpeciesReporter{<:EvaluationMetric}, 
    indiv_evals::OrderedDict{<:Individual, <:Evaluation}
)
    evaluations = values(indiv_evals)
    report = create_report(reporter, evaluations)

    return report
end

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
    if length(reporter.to_check) > 0
        species_evalutions = filter_species_evaluations(species_evalutions, reporter.to_check)
    end
    for (species_id, species) in all_species
        evaluation = all_evaluations[species_id]

        tasks = [""]
        for (cohort_id, (individuals, evaluations)) in []
            measure_set = measure(reporter, species, evaluations)
            report = BasicSpeciesReport(
                gen,
                to_print,
                to_save,
                species_id,
                cohort_id,
                reporter.metric,
                measure_set,
                reporter.print_measures,
                reporter.save_measures
            )
            push!(reports, report)
        end
    end

    return reports
end

end