module Report

using DataStructures: OrderedDict

using ...Species.Individuals.Abstract: Individual
using ...Species.Evaluators.Abstract: Evaluation
using .Metrics.Abstract: EvaluationMetric, GenotypeMetric
import .Abstract: SpeciesReporter, create_report


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

function filter_species_evaluations(
    species_evaluations::Dict{String, Dict{String, OrderedDict{<:Individual, <:Evaluation}}}, 
    filters::Vector{Pair{String, String}}
)
    result = Dict{String, Dict{String, Dict{<:Individual, <:Evaluation}}}()

    for (species_id, cohort_id) in filters
        # Check if species_id exists in species_evaluations and cohort_id exists for that species_id
        if haskey(species_evaluations, species_id) && haskey(species_evaluations[species_id], cohort_id)
            # If result doesn't have this species_id yet, initialize it
            if !haskey(result, species_id)
                result[species_id] = Dict{String, Dict{<:Individual, <:Evaluation}}()
            end
            # Copy the data for the given cohort_id
            result[species_id][cohort_id] = species_evaluations[species_id][cohort_id]
        end
    end

    return result
end


function measure(
    reporter::SpeciesReporter{<:IndividualMetric},
    indiv_evals::OrderedDict{<:Individual, <:Evaluation}
)
    individuals = collect(keys(indiv_evals))
    measure_set = measure(reporter, individuals)
    return measure_set
end

function measure(
    reporter::SpeciesReporter{<:EvaluationMetric},
    indiv_evals::OrderedDict{<:Individual, <:Evaluation}
)
    evaluations = collect(values(indiv_evals))
    measure_set = measure(reporter, evaluations)
    return measure_set
end

function measure(
    reporter::SpeciesReporter{<:GenotypeMetric},
    indiv_evals::OrderedDict{<:Individual, <:Evaluation}
)
    genotypes = [indiv.geno for indiv in keys(indiv_evals)]
    measure_set = measure(reporter, genotypes)
    return measure_set
end

function create_reports(
    reporter::BasicSpeciesReporter{<:SpeciesMetric},
    gen::Int,
    to_print::Bool,
    to_save::Bool,
    ::Vector{Observation},
    species_evalutions::Dict{String, Dict{String, Dict{<:Individual, <:Evaluation}}}
)
    reports = Report[]
    if length(reporter.to_check) > 0
        species_evalutions = filter_species_evaluations(species_evalutions, reporter.to_check)
    end
    for (species_id, cohort_id_indiv_evals) in species_id_evalutions
        for (cohort_id, indiv_evals) in cohort_id_indiv_evals
            measure_set = measure(reporter, indiv_evals)
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