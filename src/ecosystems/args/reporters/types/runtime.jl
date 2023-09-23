export RuntimeReporter, RuntimeReport

using ....CoEvo.Abstract: Reporter, Report

struct RuntimeReport <: Report
    gen::Int
    eval_time::Float64
    reproduce_time::Float64
end

Base.@kwdef struct RuntimeReporter <: Reporter
    log_interval::Int = 1
    file_report::Bool = false
    n_round::Int = 2
end

function(reporter::RuntimeReporter)(; gen::Int, eval_time::Float64, reproduction_time::Float64)
    eval_time = round(eval_time, digits=reporter.n_round)
    reproduction_time = round(reproduction_time, digits=reporter.n_round)
    if gen % reporter.log_interval == 0
        println("Runtime: $eval_time eval time, $reproduction_time reproduction")
    end
    if reporter.file_report
        return RuntimeReport(gen, eval_time, reproduction_time)
    end
end