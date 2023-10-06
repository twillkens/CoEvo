module Structs

using ....Reporters.Abstract: Reporter, Report

using DataStructures: OrderedDict
using .....Metrics.Abstract: Metric
using ....Reporters.Abstract: Report, Reporter
import ....Reporters.Interfaces: create_report, measure
using .....Ecosystems.Interactions.Observers.Abstract: Observation
using .....Ecosystems.Species.Evaluators.Abstract: Evaluation
using .....Ecosystems.Species.Abstract: AbstractSpecies

struct BasicReport{MET, MEA} <: Report{MET, MEA}
    to_print::Bool
    to_save::Bool
    metric::MET
    measurement::MEA
end

Base.@kwdef struct BasicReporter{M} <: Reporter{M}
    metric::M
    print_interval::Int = 1
    save_interval::Int = 0
end

function create_report(
    reporter::BasicReporter,
    gen::Int,
    species_evaluations::Dict{<:AbstractSpecies, <:Evaluation},
    observations::Vector{<:Observation}
)
    to_print = reporter.print_interval > 0 && gen % reporter.print_interval == 0
    to_save = reporter.save_interval > 0 && gen % reporter.save_interval == 0
    measurement = measure(reporter, species_evaluations, observations)
    report = BasicReport(
        to_print,
        to_save,
        reporter.metric,
        measurement
    )
    return report
end

end