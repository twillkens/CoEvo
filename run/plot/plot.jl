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
    aggregate_metrics_to_include::Vector{String} = ["mean"]
)
    experiment_configuration = get_experiment_configuration(file)
    trial = read(file["configuration/globals/trial"])
    generations = keys(file["generations"])
    measurements = PredictionGameAggregateMeasurement[]
    for gen in generations
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


using FilePathsBase

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

    hdf5_files = list_hdf5_files(experiment_directory)
    measurements = map(hdf5_files) do file_path
        file = h5open(file_path, "r")
        measurements = get_all_measurements(file)
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
    loconf, hiconf = confint(OneSampleTTest(values))
    measurement = PredictionGameSuperAggregateMeasurement(
        key, 
        mean(values),
        loconf,
        hiconf
    )
    return measurement
end

function aggregate(
    measurements::Dict{PredictionGameAggregateKey, Vector{Float64}}
)
    measurements = map(collect(measurements)) do (key, values)
        measurement = aggregate(key, values)
        return measurement
    end
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

function make_plots(;
    game::String = "continuous_prediction_game", 
    topology::String = "two_competitive",
    substrate::String = "function_graphs",
    reproducer::String = "disco",
)
    measurements = get_all_measurements(game, topology, substrate, reproducer)
    measurements = parse_measurements_to_dict(measurements)
    measurements = aggregate(measurements)
    make_plots(measurements)
end