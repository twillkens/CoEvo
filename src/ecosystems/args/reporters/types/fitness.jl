export FitnessReporter

using DataStructures: OrderedDict
using .Utilities: StatFeatures, SpeciesStatReport
using ...CoEvo.Abstract: Reporter, Report, Individual
using ...CoEvo.Ecosystems.Species.Evaluations: ScalarFitnessEvaluation

Base.@kwdef struct FitnessReporter <: Reporter
    n_round::Int = 2
    log_interval::Int = 1
    check_pop::Bool = true
    check_children::Bool = true
    log_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
    file_report::Bool = false
end

# Then, for the custom show method:
function Base.show(io::IO, report::SpeciesStatReport, reporter::FitnessReporter)
    println(io, "Report for Generation: $(report.gen)")
    println(io, "Species ID: $(report.species_id)")
    println(io, "Group: $(report.group_id)")
    println(io, "Metric: $(report.metric)")
    
    for feature in reporter.log_features
        val = getfield(report.stat_features, feature)
        println(io, "    $feature: $val")
    end
end

function log_report(report::SpeciesStatReport)
    show(report)
end

function generate_reports(
    gen::Int,
    evals::Dict{String, OrderedDict{<:Individual, ScalarFitnessEvaluation}},
    group::String,
    reporter::FitnessReporter
)::Vector{SpeciesStatReport}
    reports = []
    for (species_id, evaluation) in evals
        fitnesses = map(e -> e.fitness, values(evaluation))
        stats = StatFeatures("Fitness", fitnesses, reporter.n_round)
        report = SpeciesStatReport(
            gen, species_id, group, "Fitness", stats
        )
        push!(reports, report)

        if gen % reporter.log_interval == 0
            Base.show(report)
        end
    end
    return reports
end

function(reporter::FitnessReporter)(;
    gen::Int,
    all_pop_evals::Dict{String, OrderedDict{<:Individual, ScalarFitnessEvaluation}},
    all_children_evals::Dict{String, OrderedDict{<:Individual, <:ScalarFitnessEvaluation}},
)

    reports = Report[]

    if reporter.check_pop
        append!(reports, generate_reports(gen, all_pop_evals, "pop", reporter))
    end

    if reporter.check_children
        append!(reports, generate_reports(gen, all_children_evals, "children", reporter))
    end
    if reporter.file_report
        return reports
    end
    return Report[]
end

