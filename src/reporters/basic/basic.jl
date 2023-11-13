module Basic

export NullReport, BasicReport, BasicReporter, create_report

import ..Reporters: create_report

using DataStructures: OrderedDict
using ...Metrics: Metric, Measurement, measure
using ...States: State
using ..Reporters: Reporter, Report

struct NullReport <: Report end

Base.@kwdef struct BasicReport{MET <: Metric, MEA <: Measurement} <: Report
    metric::MET
    measurements::Vector{MEA}
    trial::Int = 1
    generation::Int = 1
    to_print::Bool = true
    to_save::Bool = false
end

Base.@kwdef struct BasicReporter{M} <: Reporter
    metric::M
    print_interval::Int = 1
    save_interval::Int = 0
end

function create_report(reporter::BasicReporter, state::State)
    metric = reporter.metric
    trial = state.trial
    generation = state.generation
    to_print = reporter.print_interval > 0 && generation % reporter.print_interval == 0
    to_save = reporter.save_interval > 0 && generation % reporter.save_interval == 0
    if !to_print && !to_save
        return NullReport()
    end
    measurements = measure(metric, state)
    report = BasicReport(metric, measurements, trial, generation, to_print, to_save)
    return report
end

end