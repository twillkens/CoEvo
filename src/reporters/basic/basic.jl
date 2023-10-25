module Basic

export BasicReport, BasicReporter

import ..Reporters: create_report

using DataStructures: OrderedDict
using ...Metrics: Metric, measure
using ...States: State
using ..Reporters: Reporter, Report

struct BasicReport{MET, MEA} <: Report{MET, MEA}
    generation::Int
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

function create_report(reporter::BasicReporter, state::State)
    generation = state.generation
    to_print = reporter.print_interval > 0 && generation % reporter.print_interval == 0
    to_save = reporter.save_interval > 0 && generation % reporter.save_interval == 0
    measurement = measure(reporter.metric, state)
    report = BasicReport(
        generation,
        to_print,
        to_save,
        reporter.metric,
        measurement
    )
    return report
end

end