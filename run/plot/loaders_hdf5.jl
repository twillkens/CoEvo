using HDF5: File, read, h5open
using CoEvo.Names
import CoEvo.Metrics.Aggregators: aggregate

function get_measurement(
    file::File, gen::Int, species_id::String, metric::String, submetric::String
)
    trial = read(file["configuration/globals/trial"])
    metric_path = "generations/$gen/species/$species_id/$metric"
    base_path = "trials/$trial/$metric_path"
    if haskey(file, metric_path)
        metric_group = file[metric_path]
        if haskey(metric_group, submetric)
            submetric_value = read(metric_group[submetric])
            measurement = BasicMeasurement("$base_path/$submetric", Float64(submetric_value))
            return measurement
        else
            throw(ErrorException("Submetric $submetric not found in $base_path"))
        end
    else
        throw(ErrorException("Metric $metric not found in $base_path"))
    end
end

function get_measurement(
    experiment_dir::String, 
    trial::Int, 
    gen::Int, 
    species_id::String, 
    metric::String, 
    submetric::String
)
    file_path = "$experiment_dir/$trial.h5"
    file = h5open(file_path, "r")
    measurement = get_measurement(file, trial, gen, species_id, metric, submetric)
    close(file)
    return measurement
end

function get_measurements(
    file::File, generations::Vector{Int}, species_id::String, metric::String, submetric::String,
)
    measurement_pairs = map(generations) do gen
        measurement = get_measurement(file, gen, species_id, metric, submetric)
        return gen => measurement
    end
    measurements = Dict(measurement_pairs)
    return measurements
end

function get_measurements(
    file::String, generations::Vector{Int}, species_id::String, metric::String, submetric::String
)
    file = h5open(file, "r")
    measurements = get_measurements(file, generations, species_id, metric, submetric)
    close(file)
    return measurements
end

function get_measurements(
    experiment_directory::String, 
    trials::Vector{Int},
    generations::Vector{Int},
    species_id::String, 
    metric::String, 
    submetric::String,
)
    measurement_pairs = map(trials) do trial
        file_path = "$experiment_directory/$trial.h5"
        file = h5open(file_path, "r")
        measurements = get_measurements(file, generations, species_id, metric, submetric)
        close(file)
        return trial => measurements
    end
    measurements = Dict(measurement_pairs)
    return measurements
end


const PATH = "trials/continuous_prediction_game/two_competitive/function_graphs/disco"

function extract_measurements(data::Dict{Int, Dict{Int, BasicMeasurement{Float64}}})
    # Find unique generations across all trials
    generations = unique(sort([gen for trial in values(data) for gen in keys(trial)]))

    # Initialize a vector of vectors to store measurements
    measurements = map(generations) do gen
        # Collect measurements for each generation across trials
        generation_measurements = [trial[gen] for trial in values(data) if haskey(trial, gen)]
        return gen => generation_measurements
    end
    measurements = Dict(measurements)
    return measurements
end

function aggregate(
    aggregators::Vector{<:Aggregator},
    species_id::String,
    metric::String,
    submetric::String,
    measurements::Dict{Int, Vector{BasicMeasurement{Float64}}},
)
    measurements = collect(measurements)
    measurements = map(measurements) do (generation, generation_measurements)
        base_path = "gen/$generation/species/$species_id/$metric/$submetric"
        aggregated_measurements = [
            aggregate(aggregator, base_path, generation_measurements) 
            for aggregator in aggregators
        ]
        aggregated_measurements = vcat(aggregated_measurements...)
        return generation => aggregated_measurements
    end
    measurements = Dict(measurements)
    return measurements
end

struct AggregateSpeciesMeasurement
    generation::Int
    species_id::String
    metric::String
    submetric::String
    subsubmetric::String
    value::Float64
end

struct GenerationMeasurement
    generation::Int
    measurements::Vector{AggregateSpeciesMeasurement}
end

function aggregate(
    experiment_directory::String, 
    trials::Vector{Int},
    generations::Vector{Int},
    species_id::String, 
    metric::String, 
    submetric::String,
    aggregators = [
        BasicQuantileAggregator(),
        BasicStatisticalAggregator(),
        OneSampleTTestAggregator(),
    ]
)
    measurements = get_measurements(
        experiment_directory, trials, generations, species_id, metric, submetric
    )
    measurements = extract_measurements(measurements)
    measurements = aggregate(aggregators, species_id, metric, submetric, measurements)
    return measurements
end

function parse_measurements(measurements::Dict{Int, Vector{BasicMeasurement}})
    measurements = collect(measurements)
    println("measurements: ", measurements)
    agg_measurements = map(measurements) do (generation, measurement_vector)
        println("generation: ", generation)
        generation_measurements = map(measurement_vector) do measurement
            # Parse the identifier string
            parts = string.(split(measurement.name, "/"))

            # Extract relevant information
            # Assuming the identifier format is consistent and has all parts
            generation = parse(Int, match(r"\d+", parts[2]).match)
            species_id = parts[4]
            metric = parts[5]
            submetric = parts[6]
            subsubmetric = parts[7]
            value = measurement.value

            # Create an AggregateSpeciesMeasurement and add it to the list
            measurement = AggregateSpeciesMeasurement(
                generation, species_id, metric, submetric, subsubmetric, value
            )
            return measurement
        end
        return generation => generation_measurements
    end
    agg_measurements = Dict(agg_measurements)

    return agg_measurements
end
using DataFrames

function measurements_to_dataframe(
    measurements::Dict{Int64, Vector{AggregateSpeciesMeasurement}}
)
    # Create an empty DataFrame with the desired columns
    df = DataFrame(
        generation = Int[],
        species_id = String[],
        metric = String[],
        submetric = String[],
        subsubmetric = String[],
        value = Float64[]
    )

    # Iterate through each generation and its corresponding measurements
    for (gen, agg_measurements) in measurements
        for measurement in agg_measurements
            push!(
                df,
                Dict(
                    :generation => gen,
                    :species_id => measurement.species_id,
                    :metric => measurement.metric,
                    :submetric => measurement.submetric,
                    :subsubmetric => measurement.subsubmetric,
                    :value => measurement.value
                )
            )
        end
    end
    
    # Sort the DataFrame by generation
    sort!(df, :generation)
    
    return df
end

using DataFrames
using Plots: plot, xlabel!, ylabel!, savefig, plot!
using CSV
using DataFrames
using Plots
using CSV

function plot_results(
    df::DataFrame;
    species_ids::Vector{String} = ["H"],
    metrics::Vector{String} = ["minimized_genotype_size"],
    submetric::String = "mean",
    x_labels::Vector{String} = fill("Generation", length(metrics)),
    y_labels::Vector{String} = fill("Value", length(metrics)),
    legend::Bool = true,
    plot_title_prefix::String = "Metric:",
    y_limits = [(0, 100), (0, 25), (0, 1)],
    file_prefix::String = "plot_",
    colors::Vector{Symbol} = fill(:auto, length(species_ids)),
    linewidth::Int = 3
)
    for (i, metric) in enumerate(metrics)
                println("Processing metric: ", metric)  # Debug: Current metric being processed
        p = plot(ylim=y_limits[i], legend=legend, title="$(plot_title_prefix) $(metric)")

        for (idx, species_id) in enumerate(species_ids)
            # Filter the DataFrame for the current species and metric
            filtered_df = filter(row -> row[:species_id] == species_id && row[:metric] == metric, df)

            # Check if filtered DataFrame is not empty
            if size(filtered_df, 1) > 0
                # Extract data for plotting
                generations = filtered_df[filtered_df.subsubmetric .== "mean", :generation]
                means = filtered_df[filtered_df.subsubmetric .== "mean", :value]
                lower_confidence = filtered_df[filtered_df.subsubmetric .== "lower_confidence", :value]
                upper_confidence = filtered_df[filtered_df.subsubmetric .== "upper_confidence", :value]

                ribbon_below = means .- lower_confidence
                ribbon_above = upper_confidence .- means

                color_choice = colors[mod1(idx, length(colors))]

                # Plot data with ribbon
                plot!(
                    p, generations, means, ribbon=(ribbon_below, ribbon_above),
                    label=species_id, fillalpha=0.3, color=color_choice, linewidth=linewidth,
                    legend=:topleft
                )
            else
                println("No data found for species $(species_id) and metric $(metric)!")
            end
        end

        # Set labels and save the plot
        xlabel!(p, x_labels[i])
        ylabel!(p, y_labels[i])
        savefig(p, "$(file_prefix)$(metric).png")
    end
end
