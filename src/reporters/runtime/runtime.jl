module Runtime

export RuntimeReporter, RuntimeReport, create_runtime_report

using ..Reporters: Reporter, Report
using ...Metrics: Metric
using ...Measurements: Measurement

struct RuntimeMetric <: Metric end

struct RuntimeMeasurement <: Measurement end

struct RuntimeReport{M, MEA} <: Report{M, MEA}
    gen::Int
    metric::M
    measurement::MEA
    eco_id::String
    to_print::Bool
    to_save::Bool
    eval_time::Float64
    reproduce_time::Float64
end

Base.@kwdef struct RuntimeReporter{MET <: Metric} <: Reporter{MET}
    metric::MET = RuntimeMetric()
    print_interval::Int = 1
    save_interval::Int = 0
    n_round::Int = 5
end

function Base.show(io::IO, report::RuntimeReport)
end

# Define how a RuntimeReporter produces a report.
function create_runtime_report(
    reporter::RuntimeReporter, 
    eco_id::String, 
    gen::Int, 
    eval_time::Float64, 
    reproduce_time::Float64
)
    to_print = reporter.print_interval > 0 && gen % reporter.print_interval == 0
    to_save = reporter.save_interval > 0 && gen % reporter.save_interval == 0
    report = RuntimeReport(
        gen, 
        RuntimeMetric(),
        RuntimeMeasurement(),
        eco_id,
        to_print, 
        to_save, 
        round(eval_time, digits = reporter.n_round), 
        round(reproduce_time, digits = reporter.n_round)
    )
    return report 
end

end