export RuntimeReport

using ....CoEvo.Abstract: Report

struct RuntimeReport <: Report
    eval_time::Float64
    reproduce_time::Float64
end
