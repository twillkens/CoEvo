export RuntimeReporter

using ...CoEvo.Abstract: Reporter

Base.@kwdef struct RuntimeReporter <: Reporter
    print_interval::Int = 1
    save_interval::Int = 0
end

function(reporter::RuntimeReporter)(gen::Int, eval_time::Float64, reproduce_time::Float64)
    to_print = reporter.print_interval > 0 && gen % reporter.print_interval == 0
    to_save = reporter.save_interval > 0 && gen % reporter.save_interval == 0
    report = RuntimeReport(to_print, to_save, eval_time, reproduce_time)
    return report 
end