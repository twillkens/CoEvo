ENV["GKSwstype"] = "100"
using FilePathsBase
using Serialization
using HDF5: File, read, h5open, Group, names
using StatsBase: mean
using HypothesisTests: OneSampleTTest, confint
using CoEvo.Names: Aggregator
using Plots: plot, plot!, gr, savefig, Plot

gr()

struct ExperimentConfiguration
    game::String
    topology::String
    substrate::String
    reproducer::String
end

struct PredictionGameAggregateMeasurement
    experiment_configuration::ExperimentConfiguration
    trial::Int
    generation::String
    species_id::String
    metric::String
    aggregate_metric::String
    value::Float64
end


function get_experiment_configuration(file::File)
    game = read(file["configuration/game/id"])
    topology = read(file["configuration/topology/id"])
    substrate = read(file["configuration/substrate/id"])
    reproducer = read(file["configuration/reproducer/id"])
    return ExperimentConfiguration(game, topology, substrate, reproducer)
end

function get_aggregate_value_path(
    generation::String, species_id::String, metric::String, aggregate_metric::String
)
    return "generations/$generation/species/$species_id/$metric/$aggregate_metric"
end


function get_all_measurements(
    file::File, 
    metrics_to_include::Vector{String} = [
        "genotype_size", "minimized_genotype_size", "scaled_fitness"
    ],
    aggregate_metrics_to_include::Vector{String} = ["mean"],
    interval::Int = 50,
    max_generations::Int = 4950
)
    experiment_configuration = get_experiment_configuration(file)
    trial = read(file["configuration/globals/trial"])
    println("Processing trial $trial")
    println("configuration: $experiment_configuration")
    generations = keys(file["generations"])
    measurements = PredictionGameAggregateMeasurement[]
    for gen in generations
        to_process = gen == "1" || parse(Int, gen) % interval == 0
        if !to_process || parse(Int, gen) > max_generations
            continue
        end

        try
            modes_metrics = [
                ("complexity", "maximum"), ("change", "mean"), ("novelty", "mean")
            ]
            for (metric, submetric) in modes_metrics
                value = Float64(read(file["generations/$gen/modes/$metric"]))
                measurement = PredictionGameAggregateMeasurement(
                    experiment_configuration, 
                    trial, 
                    gen, 
                    "all",
                    metric, 
                    submetric, 
                    value
                )
                push!(measurements, measurement)
            end
        catch e 
            println(e)
            println("Modes not found for generation $gen")
        end
        println("Processing generation $gen")
        species_ids = keys(file["generations/$gen/species"])
        for species_id in species_ids
            metrics = keys(file["generations/$gen/species/$species_id"])
            metrics = filter(m -> m != "population", metrics)
            metrics = filter(m -> m in metrics_to_include, metrics) 
            for metric in metrics
                aggregate_metrics = keys(file["generations/$gen/species/$species_id/$metric"])
                aggregate_metrics = filter(m -> m in aggregate_metrics_to_include, aggregate_metrics)
                for aggregate_metric in aggregate_metrics
                    value_path = get_aggregate_value_path(gen, species_id, metric, aggregate_metric)
                    value = Float64(read(file[value_path]))
                    measurement = PredictionGameAggregateMeasurement(
                        experiment_configuration, 
                        trial, 
                        gen, 
                        species_id, 
                        metric, 
                        aggregate_metric, 
                        value
                    )
                    push!(measurements, measurement)
                end
            end
        end
    end
    measurements = vcat(filter(m -> m !== nothing, measurements)...)
    return measurements
end

"""
    find_max_generation(directory::String)

Sweep the archives in the specified directory to find the maximum generation number reached.
"""
function find_max_generation(directory::String)
    max_generation = 0
    hdf5_files = list_hdf5_files(directory)

    
    for file_path in hdf5_files
        println("Checking $file_path for max generation")
        file = h5open(file_path, "r")
        
        try
            generations = keys(file["generations"])
            for gen in generations
                gen_number = parse(Int, gen)
                max_generation = max(max_generation, gen_number)
            end
        catch e
            println("Error processing file $file_path: $e")
        finally
            close(file)
        end
    end

    return max_generation
end

"""
    find_lowest_max_generation(directory::String)

Find the lowest maximum generation number reached among all trials in the specified directory.
"""
function find_lowest_max_generation(directory::String)
    lowest_max_generation = Inf  # Start with infinity, to ensure any real max is lower
    hdf5_files = list_hdf5_files(directory)

    for file_path in hdf5_files
        println("Checking $file_path for max generation")
        file_max_generation = 0  # Track the max generation for this file
        file = h5open(file_path, "r")

        try
            generations = keys(file["generations"])
            for gen in generations
                gen_number = parse(Int, gen)
                file_max_generation = max(file_max_generation, gen_number)
            end
            # Compare this file's max generation with the lowest found so far
            lowest_max_generation = min(lowest_max_generation, file_max_generation)
        catch e
            println("Error processing file $file_path: $e")
        finally
            close(file)
        end
    end

    # Handle case where no generations were found
    if isinf(lowest_max_generation)
        lowest_max_generation = 0
    end

    return lowest_max_generation
end


function list_hdf5_files(directory::String)
    hdf5_files = []
    for file in readdir(directory, join=true)
        if isfile(file) && endswith(file, ".h5")
            push!(hdf5_files, file)
        end
    end
    return hdf5_files
end

"game/topology/substrate/reproducer/trial_id/generation_id/species_id/metric/submetric/subsubmetric"

function get_all_measurements(
    game::String = "continuous_prediction_game", 
    topology::String = "two_competitive",
    substrate::String = "function_graphs",
    reproducer::String = "disco",
)
    root_directory = ENV["COEVO_TRIAL_DIR"]
    experiment_directory = "$root_directory/$game/$topology/$substrate/$reproducer"

    metrics_to_include = [
        "genotype_size", "minimized_genotype_size", "scaled_fitness"
    ]
    aggregate_metrics_to_include = ["mean"]
    interval = 50
    max_generations = find_lowest_max_generation(experiment_directory)

    hdf5_files = list_hdf5_files(experiment_directory)
    measurements = map(hdf5_files) do file_path
        println("Processing $file_path")
        file = h5open(file_path, "r")
        measurements = get_all_measurements(
            file, metrics_to_include, aggregate_metrics_to_include, interval, max_generations
        )
        close(file)
        return measurements
    end
    measurements = vcat(measurements...)

    return measurements
end

struct PredictionGameSuperAggregator end


struct PredictionGameAggregateKey
    experiment_configuration::ExperimentConfiguration
    generation::String
    species_id::String
    metric::String
    aggregate_metric::String
end

import Base: show

function show(io::IO, key::PredictionGameAggregateKey)
    ec = key.experiment_configuration
    s = "$(ec.topology)/$(ec.reproducer)/$(key.generation)/$(key.species_id)/$(key.metric)/$(key.aggregate_metric)"
    print(io, s)
end


function PredictionGameAggregateKey(measurement::PredictionGameAggregateMeasurement)
    key = PredictionGameAggregateKey(
        measurement.experiment_configuration,
        measurement.generation,
        measurement.species_id,
        measurement.metric,
        measurement.aggregate_metric
    )
    return key
end

function parse_measurements_to_dict(measurements::Vector{PredictionGameAggregateMeasurement})
    measurement_dict = Dict{PredictionGameAggregateKey, Vector{Float64}}()

    for m in measurements
        key = PredictionGameAggregateKey(m)
        if haskey(measurement_dict, key)
            push!(measurement_dict[key], m.value)
        else
            measurement_dict[key] = [m.value]
        end
    end

    return measurement_dict
end

struct PredictionGameSuperAggregateMeasurement
    key::PredictionGameAggregateKey
    mean::Float64
    lower_confidence::Float64
    upper_confidence::Float64
end

function aggregate(
    key::PredictionGameAggregateKey,
    values::Vector{Float64}
)
    if length(values) == 0
        return nothing
    elseif length(values) == 1
        return PredictionGameSuperAggregateMeasurement(
            key, 
            values[1], 
            values[1], 
            values[1]
        )
    else
        loconf, hiconf = confint(OneSampleTTest(values))
        measurement = PredictionGameSuperAggregateMeasurement(
            key, 
            mean(values),
            loconf,
            hiconf
        )
        return measurement
    end
end

function aggregate(
    measurements::Dict{PredictionGameAggregateKey, Vector{Float64}}
)
    measurements = map(collect(measurements)) do (key, values)
        measurement = aggregate(key, values)
        return measurement
    end
    measurements = vcat(filter(m -> m !== nothing, measurements)...)
    return measurements
end


function group_by_metrics(measurements::Vector{PredictionGameSuperAggregateMeasurement})
    grouped = Dict{String, Vector{PredictionGameSuperAggregateMeasurement}}()
    for m in measurements
        metric = m.key.metric
        if haskey(grouped, metric)
            push!(grouped[metric], m)
        else
            grouped[metric] = [m]
        end
    end
    return grouped
end

function safe_parse_int(str::String)
    try
        return parse(Int, str)
    catch
        return -1  # return an invalid value to indicate parse failure
    end
end
function plot_measurements(metric, measurements)
    # Determine common experiment configuration for the title (assuming it's the same for all measurements)
    if !isempty(measurements)
        common_config = measurements[1].key.experiment_configuration
        plot_title = "Game: $(common_config.game)\nTopology: $(common_config.topology)\nSubstrate: $(common_config.substrate)\nReproducer: $(common_config.reproducer)\nMetric: $metric"
    else
        plot_title = "Metric: $metric"
    end

    p = plot(title=plot_title, xlabel="Generation", ylabel=metric, size=(800, 600))

    # Group measurements by species
    species_grouped = Dict{String, Vector{PredictionGameSuperAggregateMeasurement}}()
    for m in measurements
        species = m.key.species_id
        if haskey(species_grouped, species)
            push!(species_grouped[species], m)
        else
            species_grouped[species] = [m]
        end
    end

    # Plot each species with a different color
    for (species, species_measurements) in species_grouped
        sort!(species_measurements, by = m -> safe_parse_int(m.key.generation))

        x = [safe_parse_int(m.key.generation) for m in species_measurements]
        y = [m.mean for m in species_measurements]
        ribbon_below = [m.mean - m.lower_confidence for m in species_measurements]
        ribbon_above = [m.upper_confidence - m.mean for m in species_measurements]

        valid_indices = findall(x .!= -1)
        x = x[valid_indices]
        y = y[valid_indices]
        ribbon_below = ribbon_below[valid_indices]
        ribbon_above = ribbon_above[valid_indices]

        plot!(p, x, y, ribbon=(ribbon_below, ribbon_above), label=species, fillalpha=0.3)
    end

    return p
end

function generate_plots(grouped_measurements)
    plots = []
    for (metric, measurements) in grouped_measurements
        key = measurements[1].key
        p = plot_measurements(metric, measurements)
        push!(plots, key => p)
    end
    return Dict(plots)
end

function get_plots_path(experiment_configuration::ExperimentConfiguration)
    game = experiment_configuration.game
    topology = experiment_configuration.topology
    substrate = experiment_configuration.substrate
    reproducer = experiment_configuration.reproducer
    return "plots/$game/$topology/$substrate/$reproducer"
end

function display_or_save_plots(plots::Dict{PredictionGameAggregateKey, <:Plot})
    for (key, p) in plots
        plots_path = get_plots_path(key.experiment_configuration)
        if !ispath(plots_path)
            mkpath(plots_path)
        end
        metric = key.metric
        plot_path = "$plots_path/$metric.png"
        savefig(p, plot_path)
    end
end

function make_plots(measurements::Vector{PredictionGameSuperAggregateMeasurement})
    grouped = group_by_metrics(measurements)
    plots = generate_plots(grouped)
    display_or_save_plots(plots)
end

function make_plots(
    game::String = "continuous_prediction_game", 
    topology::String = "two_competitive",
    substrate::String = "function_graphs",
    reproducer::String = "disco",
)
    measurements = get_all_measurements(game, topology, substrate, reproducer)
    measurements = parse_measurements_to_dict(measurements)
    measurements = aggregate(measurements)

    serialize("$game-$topology-$substrate-$reproducer.jls", measurements)
    make_plots(measurements)
end

using FilePathsBase


function contains_h5_files(dir_path::String)
    return any(endswith.(readdir(dir_path), ".h5"))
end

using FilePathsBase

function make_plots(root::String)
    configs = find_experiment_configurations(root)
    for config in configs
        println("Processing $config")
        make_plots(config.game, config.topology, config.substrate, config.reproducer)
    end
end

function make_plots()
    root = ENV["COEVO_TRIAL_DIR"]
    make_plots(root)
end

function find_experiment_configurations(root_dir::String)
    configurations = ExperimentConfiguration[]
    for dir_path in walkdir(root_dir)
        if is_valid_experiment_path(dir_path)
            config = parse_experiment_configuration(dir_path)
            push!(configurations, config)
        end
    end
    return configurations
end

function is_valid_experiment_path(dir_path::Tuple{String, Vector{String}, Vector{String}})
    return length(dir_path[3]) > 0
    # Implement logic to determine if a path corresponds to a valid experiment
    # For example, by checking the directory structure or file existence
end

function parse_experiment_configuration(dir_path::Tuple{String, Vector{String}, Vector{String}})
    # Extract the configuration details from the directory path
    # Example: "root/game/topology/substrate/reproducer"
    path_parts = split(dir_path[1], "/")
    if length(path_parts) >= 5
        game, topology, substrate, reproducer = path_parts[end-3:end]
        return ExperimentConfiguration(game, topology, substrate, reproducer)
    end
    return nothing
end
