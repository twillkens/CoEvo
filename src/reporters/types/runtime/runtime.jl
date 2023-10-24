module Runtime

export RuntimeReporter, RuntimeReport, create_runtime_report

using ...Reporters.Abstract: Reporter, Report
using ....Ecosystems.Metrics.Abstract: Metric
using ....Ecosystems.Measurements.Abstract: Measurement


struct RuntimeMetric <: Metric end
struct RuntimeMeasurement <: Measurement end
"""
    RuntimeReport

A structured report that captures the runtime details of the evaluation and reproduction 
processes during a specific generation.

# Fields
- `gen`: The generation number.
- `to_print`: A boolean flag indicating if this report should be printed.
- `to_save`: A boolean flag indicating if this report should be saved.
- `eval_time`: The time taken (in seconds) for the evaluation process.
- `reproduce_time`: The time taken (in seconds) for the reproduction process.
"""
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

"""
    RuntimeReporter

A reporter type that produces [`RuntimeReport`](@ref) objects when called. It can be configured 
to print and/or save reports at specific generation intervals.

# Fields
- `print_interval`: The interval (in terms of generations) at which reports should be printed. A value of 0 disables printing.
- `save_interval`: The interval (in terms of generations) at which reports should be saved. A value of 0 disables saving.
- `n_round`: The number of decimal places to which the `eval_time` and `reproduce_time` should be rounded.

# Usage
Create an instance of `RuntimeReporter` and call it with the necessary arguments to generate a report.
"""
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