module Basic

export BasicReport, BasicReporter, create_report

import ..Reporters: create_report

using DataStructures: OrderedDict
using ...Metrics: Metric, Measurement, measure
using ...States: State
using ..Reporters: Reporter, Report

struct BasicReport{MET <: Metric, MEA <: Measurement} <: Report
    generation::Int
    to_print::Bool
    to_save::Bool
    metric::MET
    measurement::MEA
end

Base.@kwdef struct BasicReporter{M} <: Reporter
    metric::M
    print_interval::Int = 1
    save_interval::Int = 0
end

function create_report(reporter::BasicReporter, state::State)
    generation = state.generation
    to_print = reporter.print_interval > 0 && generation % reporter.print_interval == 0
    to_save = reporter.save_interval > 0 && generation % reporter.save_interval == 0
    measurement = measure(reporter.metric, state)
    report = BasicReport(generation, to_print, to_save, reporter.metric, measurement)
    return report
end

end