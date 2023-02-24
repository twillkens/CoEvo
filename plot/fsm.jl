using CoEvo
using Plots

function plotsize(eco::String, trial::Int)
    jld = jldopen("$(ENV["FSM_DATA_DIR"])/$(eco)/$(eco)-$(trial).jld2")
    allgens = jld["gens"]
    sizes = Dict()
    for (gen, gengroup) in allgens
        sizes[gen] = length(gengroup)

end