export RuntimeReport

using ....CoEvo.Abstract: Report

struct RuntimeReport <: Report
    to_print::Bool
    to_save::Bool
    eval_time::Float64
    reproduce_time::Float64
end
