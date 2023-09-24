export FitnessReporter

using DataStructures: OrderedDict
using .Reports: SpeciesStatisticalFeatureReport
using ...CoEvo.Abstract: Reporter, Report, Individual
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
    evals::Dict{String, OrderedDict{<:Individual, ScalarFitnessEvaluation}},
    group::String,
    reporter::FitnessReporter
)::Vector{SpeciesStatReport}
    reports = []
    for (species_id, evaluations) in evals
        fitnesses = map(e -> e.second.fitness, values(evaluations))
        stat_features = StatisticalFeatureSet(fitnesses, reporter.n_round)
        report = SpeciesStatisticalFeatureReport(
            gen, species_id, group, "Fitness", stat_features
        )
        push!(reports, report)

        if gen % reporter.log_interval == 0
            Base.show(report)
        end
    end
    return reports
end

function(reporter::FitnessReporter)(gen::Int;
    all_pop_evals::Dict{String, OrderedDict{<:Individual, ScalarFitnessEvaluation}},
    all_children_evals::Dict{String, OrderedDict{<:Individual, <:ScalarFitnessEvaluation}},
    kwargs...
)

    reports = SpeciesStatisticalFeatureReport[]

    if reporter.check_pop
        append!(reports, generate_reports(gen, all_pop_evals, "pop", reporter))
    end

    if reporter.check_children
        append!(reports, generate_reports(gen, all_children_evals, "children", reporter))
    end
    reports
end

