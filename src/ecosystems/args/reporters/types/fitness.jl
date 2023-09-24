export FitnessReporter

using DataStructures: OrderedDict
using .Reports: SpeciesStatisticalFeatureSetReport
using ...CoEvo.Abstract: Reporter, Report, Individual, SpeciesConfiguration, Observation
using ...CoEvo.Abstract: DomainConfiguration, Evaluation
using ...CoEvo.Ecosystems.Species.Evaluations: ScalarFitnessEvaluation

Base.@kwdef struct FitnessReporter <: Reporter
    print_interval::Int = 1
    save_interval::Int = 0
    check_pop::Bool = true
    check_children::Bool = true
    n_round::Int = 2
    print_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
    save_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
end

function generate_reports(
    gen::Int,
    evals::Dict{String, OrderedDict{<:Individual, <:Evaluation}},
    generational_type::String,
    reporter::FitnessReporter
)::Vector{SpeciesStatisticalFeatureSetReport}
    reports = []
    for (species_id, evaluations) in evals
        if length(evaluations) == 0 || !isa(first(values(evaluations)), ScalarFitnessEvaluation)
            continue
        end
        fitnesses = map(e -> e.second.fitness, values(evaluations))
        stat_features = StatisticalFeatureSet(fitnesses, reporter.n_round)
        to_print = reporter.print_interval > 0 && gen % reporter.print_interval == 0
        to_save = reporter.save_interval > 0 && gen % reporter.save_interval == 0
        report = SpeciesStatisticalFeatureSetReport(
            to_print, to_save, species_id, generational_type, "Fitness", stat_features,
            reporter.print_features, reporter.save_features
        )
        push!(reports, report)

    end
    return reports
end

function(reporter::FitnessReporter)(gen::Int,
    all_pop_evals::OrderedDict{SpeciesConfiguration, OrderedDict{<:Individual, <:Evaluation}},
    all_children_evals::OrderedDict{SpeciesConfiguration, OrderedDict{<:Individual, <:Evaluation}},
    dom_cfg_obs::OrderedDict{<:DomainConfiguration, <:Observation}
)

    reports = SpeciesStatisticalFeatureSetReport[]

    if reporter.check_pop
        append!(reports, generate_reports(gen, all_pop_evals, "pop", reporter))
    end

    if reporter.check_children
        append!(reports, generate_reports(gen, all_children_evals, "children", reporter))
    end
    reports
end

