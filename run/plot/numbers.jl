ENV["GKSwstype"] = "100"
using CSV
using DataFrames
using Bootstrap
using Plots: plot, plot!, title!, xlabel!, ylabel!, display, gr, savefig
using StatsBase
using Bootstrap: bootstrap, BasicSampling, BasicConfInt, confint as bootstrap_confint
using StatsBase: nquantile, skewness, kurtosis, mode, mean, var, std
using Measures
gr()

const DEFAULT_BOOTSTRAPPED_CONFIDENCE_INTERVALS = Dict(
        "lower_confidence" => 0,
        "upper_confidence" => 0,
)
const N_BOOTSTRAP_SAMPLES = 1000

const DEFAULT_CONFIDENCE = 0.95

const N_TRIALS = 5
const N_GENERATIONS = 250

function get_bootstrapped_confidence_intervals(values::Vector{Float64})
    if length(values) == 0
        return DEFAULT_BOOTSTRAPPED_CONFIDENCE_INTERVALS
    end
    bootstrap_result = bootstrap(mean, values, BasicSampling(1000))
    _, lower_confidence, upper_confidence = first(bootstrap_confint(
        bootstrap_result, BasicConfInt(DEFAULT_CONFIDENCE)
    ))
    confidence_intervals = Dict(
        "lower_confidence" => lower_confidence,
        "upper_confidence" => upper_confidence,
    )
    return confidence_intervals
end

function read_and_aggregate_data(path_pattern)
    avgmin_genes = Vector{Vector{Float64}}()
    for i in 1:5
        file_path = replace(path_pattern, "#" => string(i))
        df = CSV.read(file_path, DataFrame)
        filtered_df = filter(row -> row.species_id == "A", df)
        push!(avgmin_genes, filtered_df.avgmin_gene)
    end
    return avgmin_genes
end

function plot_data(data_continuous, data_discrete, title)
    generations_per_file = length(data_continuous[1])

    means_continuous = Float64[]
    upper_ribbon_continuous = Float64[]
    lower_ribbon_continuous = Float64[]
    means_discrete = Float64[]
    upper_ribbon_discrete = Float64[]
    lower_ribbon_discrete = Float64[]

    for gen in 1:generations_per_file
        gen_data_continuous = [data[gen] for data in data_continuous]
        gen_data_discrete = [data[gen] for data in data_discrete]

        mean_cont = mean(gen_data_continuous)
        mean_disc = mean(gen_data_discrete)

        ci_cont = get_bootstrapped_confidence_intervals(gen_data_continuous)
        ci_disc = get_bootstrapped_confidence_intervals(gen_data_discrete)

        push!(means_continuous, mean_cont)
        push!(upper_ribbon_continuous, ci_cont["upper_confidence"] - mean_cont)
        push!(lower_ribbon_continuous, mean_cont - ci_cont["lower_confidence"])

        push!(means_discrete, mean_disc)
        push!(upper_ribbon_discrete, ci_disc["upper_confidence"] - mean_disc)
        push!(lower_ribbon_discrete, mean_disc - ci_disc["lower_confidence"])
    end

    p = plot()
    plot!(p, means_continuous, ribbon = (upper_ribbon_continuous, lower_ribbon_continuous), label = "Continuous", line = :solid)
    plot!(p, means_discrete, ribbon = (upper_ribbon_discrete, lower_ribbon_discrete), label = "Discrete, δ = 0.25", line = :dash)
    plot!(p, margin = 4mm)

    title!(p, title)
    xlabel!(p, "Generation")
    ylabel!(p, "Average Minimum Dimension Size")
    return p
end




# Aggregating data
data_archive_continuous = read_and_aggregate_data("trials/archive_continuous/#.csv")
data_archive_discrete = read_and_aggregate_data("trials/archive_discrete/#.csv")
data_noarchive_continuous = read_and_aggregate_data("trials/noarchive_continuous/#.csv")
data_noarchive_discrete = read_and_aggregate_data("trials/noarchive_discrete/#.csv")

# Plotting
plot1 = plot_data(data_archive_continuous, data_archive_discrete, "DISCO-Archive\nAverage Minumum Dimension Size")
plot2 = plot_data(data_noarchive_continuous, data_noarchive_discrete, "DISCO\nAverage Minumum Dimension Size")

savefig(plot1, "trials/archive.png")
savefig(plot2, "trials/noarchive.png")


using Plots: heatmap, cgrad

function read_and_process_data_heatmap(path_pattern, trial)
    # Assuming max_index values range from 1 to 5 and generations are known (e.g., 1 to 250)
    max_index_range = 1:5
    num_generations = N_GENERATIONS  # Replace with the actual number of generations
    heatmap_matrix = zeros(Int, num_generations, length(max_index_range))

    file_path = replace(path_pattern, "#" => string(trial))
    df = CSV.read(file_path, DataFrame)

    for gen in 1:num_generations
        gen_df = filter(row -> row.species_id == "B" && row.generation == gen, df)
        for idx in max_index_range
            count = sum(gen_df[:, Symbol("maxindex_$idx")])
            heatmap_matrix[gen, idx] += count
        end
    end
    return heatmap_matrix
end
#

function plot_heatmap(data_matrix, title)
    # Normalize data_matrix to range between 0 and 1
    normalized_matrix = data_matrix ./ maximum(data_matrix)

    p = heatmap(
        1:size(normalized_matrix, 1),
        1:size(normalized_matrix, 2),
        normalized_matrix',
        color = cgrad([:white, :black]),  # Custom color gradient
        xlabel = "Generation",
        ylabel = "Maximum Dimension Count",
        title = title,
        margin = 4mm  # Adjust this value to increase or decrease padding
    )
    return p
end


for mode in ["archive_discrete", "archive_continuous", "noarchive_discrete", "noarchive_continuous"]
    for trial in 1:N_TRIALS
        pretty_title = mode in ["archive_discrete", "archive_continuous"] ?
            "DISCO-Archive: Trial $trial\nEvaluator Maximum Dimension Counts" : 
            "DISCO: Trial $trial\nEvaluator Maximum Dimension Counts"
        heatmap_data = read_and_process_data_heatmap("trials/$mode/#.csv", trial)
        heatmap_plot = plot_heatmap(heatmap_data, pretty_title)
        savefig(heatmap_plot, "trials/$mode/heatmap_$trial.png")
    end
end

# Example usage
#heatmap_data = read_and_process_data_heatmap("trials/archive_continuous/#.csv", 1)
#heatmap_plot = plot_heatmap(heatmap_data, "Archive Continuous Heatmap")
#display(heatmap_plot)
#savefig(heatmap_plot, "trials/heatmap_archive_continuous.png")


function read_and_process_avg_data(path_pattern, trial, species)
    file_path = replace(path_pattern, "#" => string(trial))
    df = CSV.read(file_path, DataFrame)

    avg_values = Dict{Symbol, Vector{Float64}}()
    for i in 1:5
        avg_values[Symbol("avgvalue_$i")] = Float64[]
    end

    for row in eachrow(df)
        if row.species_id == species
            for i in 1:5
                push!(avg_values[Symbol("avgvalue_$i")], row[Symbol("avgvalue_$i")])
            end
        end
    end
    return avg_values
end


function plot_avg_values(avg_values, title)
    p = plot(title = title, xlabel = "Generation", ylabel = "Average Dimension Value")

    colors = [:red, :green, :blue, :purple, :orange]
    for (i, key) in enumerate(keys(avg_values))
        plot!(p, avg_values[key], label = "Dimension $i", line = (:solid, 2), color = colors[i])
    end
    plot!(p, margin = 4mm)

    return p
end

for mode in ["archive_discrete", "archive_continuous", "noarchive_discrete", "noarchive_continuous"]
    for trial in 1:N_TRIALS
        for species in ["A"]
            pretty_title = mode in ["archive_discrete", "archive_continuous"] ?
                "DISCO-Archive: Trial $trial\nLearner Average Dimension Values" : 
                "DISCO: Trial $trial\nLearner Average Dimension Values"
            avg_values = read_and_process_avg_data("trials/$mode/#.csv", trial, species)
            line_plot = plot_avg_values(avg_values, pretty_title)
            savefig(line_plot, "trials/$mode/values_$trial.png")
        end
    end
end

# Example usage for a specific trial and species
avg_values = read_and_process_avg_data("trials/archive_continuous/#.csv", 1, "A")
line_plot = plot_avg_values(avg_values, "Archive Continuous Trial 1 - Species A")
display(line_plot)
savefig(line_plot, "trials/lineplot_archive_continuous_trial1_speciesA.png")

# Repeat this process for each configuration, trial, and species as needed

# Repeat the process for each configuration and trial
