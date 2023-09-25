module Abstract

using DataStructures: OrderedDict
using .....CoEvo.Abstract: Report, Individual, Evaluation, Reporter
using .....CoEvo.Abstract: CohortMetricReporter
using .....CoEvo.Abstract: EvaluationCohortMetricReporter, GenotypeCohortMetricReporter
using .....CoEvo.Utilities.Statistics: StatisticalFeatureSet
using ..Reports: CohortMetricReport

function(reporter::EvaluationCohortMetricReporter)(
    gen::Int,
    species_id::String,
    cohort::String,
    indiv_evals::OrderedDict{<:Individual, <:Evaluation}
)
    report = reporter(gen, species_id, cohort, collect(values(indiv_evals)))
    return report
end

function(reporter::GenotypeCohortMetricReporter)(
    gen::Int,
    species_id::String,
    cohort::String,
    indiv_evals::OrderedDict{<:Individual, <:Evaluation}
)
    genotypes = [indiv.geno for indiv in keys(indiv_evals)]
    report = reporter(gen, species_id, cohort, genotypes)
    return report
end

function(reporter::CohortMetricReporter)(
    gen::Int,
    species_id::String,
    cohort::String,
    values::Vector{Float64}
)
    stat_features = StatisticalFeatureSet(values, reporter.n_round)
    report = CohortMetricReport(
        reporter,
        gen,
        species_id, 
        cohort, 
        stat_features,
    )
    return report
end

end