module Reporters

export RuntimeReport, RuntimeReporter

using ...Abstract: Report, Reporter, Archiver

struct RuntimeReport <: Report
    gen::Int
    to_print::Bool
    to_save::Bool
    eval_time::Float64
    reproduce_time::Float64
end

Base.@kwdef struct RuntimeReporter <: Reporter
    print_interval::Int = 1
    save_interval::Int = 0
end

function(reporter::RuntimeReporter)(gen::Int, eval_time::Float64, reproduce_time::Float64)
    to_print = reporter.print_interval > 0 && gen % reporter.print_interval == 0
    to_save = reporter.save_interval > 0 && gen % reporter.save_interval == 0
    report = RuntimeReport(gen, to_print, to_save, eval_time, reproduce_time)
    return report 
end

function(archiver::Archiver)(report::RuntimeReport)
    if report.to_print
        println("-----------------------------------------------------------")
        println("Generation: $report.gen")
        println("Evaluation time: $(report.eval_time)")
        println("Reproduction time: $(report.reproduce_time)")
    end
end

end