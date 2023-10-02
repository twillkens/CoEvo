module Structs

using ....Reporters.Abstract: Reporter, Report

using DataStructures: OrderedDict
using .....Metrics.Abstract: Metric
using ....Reporters.Abstract: Report, Reporter

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

end