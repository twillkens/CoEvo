module Abstract

export SpeciesStatisticalFeatureSetReporter, EvaluationReporter, IndividualReporter

using DataStructures: OrderedDict
using .....CoEvo.Abstract: Report, Individual, Evaluation, Reporter
using .....CoEvo.Utilities: StatisticalFeatureSet
using ..Reports: SpeciesStatisticalFeatureSetReport

abstract type SpeciesStatisticalFeatureSetReporter <: Reporter end

abstract type EvaluationReporter <: SpeciesStatisticalFeatureSetReporter end

function(reporter::EvaluationReporter)(
    gen::Int,
    species_id::String,
    generational_type::String,
    indiv_evals::OrderedDict{<:Individual, <:Evaluation}
)
    report = reporter(gen, species_id, generational_type, collect(values(indiv_evals)))
    return report
end

abstract type IndividualReporter <: SpeciesStatisticalFeatureSetReporter end

function(reporter::IndividualReporter)(
    gen::Int,
    species_id::String,
    cohort::String,
    indiv_evals::OrderedDict{<:Individual, <:Evaluation}
)
    report = reporter(gen, species_id, cohort, collect(keys(indiv_evals)))
    return report
end

function(reporter::SpeciesStatisticalFeatureSetReporter)(
    gen::Int,
    species_id::String,
    generational_type::String,
    values::Vector{Float64}
)
    stat_features = StatisticalFeatureSet(values, reporter.n_round)
    to_print = reporter.print_interval > 0 && gen % reporter.print_interval == 0
    to_save = reporter.save_interval > 0 && gen % reporter.save_interval == 0
    report = SpeciesStatisticalFeatureSetReport(
        gen,
        to_print, 
        to_save, 
        species_id, 
        generational_type, 
        reporter.metric, 
        stat_features,
        reporter.print_features, 
        reporter.save_features
    )
    return report
end

end