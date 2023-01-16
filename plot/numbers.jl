using StatsBase, JLD2, Plots

function get_popsums(log, popkey)
    data = Float64[]
    for i in 1:600
        group = log[string(i)]["pops"][popkey]
        pop_sums = [sum(group[key]["genes"]) for key in keys(group)]
        push!(data, mean(pop_sums))
    end
    data
end


function plot_popsums(logpath::String)
    log = jldopen(logpath, "r")
    sumsA = get_popsums(log, "A")
    sumsB = get_popsums(log, "B")
    plot([sumsA, sumsB])
end