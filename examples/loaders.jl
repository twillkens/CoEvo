using JLD2
using DataFrames
using CSV
using Plots: plot, plot!, title!, xlabel!, ylabel!, savefig
using CoEvo
using CoEvo.Ecosystems.Measurements: BasicStatisticalMeasurement

function load_submetric_value(
    file::JLD2.JLDFile, gen::Int, species_id::String, metric::String, submetric::String
)
    base_path = "measurements/$gen/$metric"
    
    if haskey(file, base_path)
        species_group = file["$base_path/$species_id"]
        if haskey(species_group, submetric)
            submetric_value = species_group[submetric]
            return submetric_value
        else
            throw(ErrorException("Submetric $submetric not found in $base_path/$species_id"))
        end
    else
        throw(ErrorException("Metric $metric not found in $base_path"))
    end
end

function push_or_add!(dict::Dict{Int, Vector{Float64}}, key::Int, value::Float64)
    vec = get!(dict, key, Float64[]) # If the key doesn't exist, a new empty vector is created.
    push!(vec, value)
    return dict
end

function process_measurements(measurements_per_trial::Dict{Int, Vector{Float64}})
    # Assuming all trials have the same number of generations
    n_generations = length(first(values(measurements_per_trial)))

    # Initialize a result vector to store BasicStatisticalMeasurement structs for each generation
    results = Vector{BasicStatisticalMeasurement}(undef, n_generations)

    for gen in 1:n_generations
        # Collect the measurements for the current generation across all trials
        measurements_for_gen = [trial_measurements[gen] for trial_measurements in values(measurements_per_trial)]
        
        # Calculate statistical metrics for the current generation
        results[gen] = BasicStatisticalMeasurement(measurements_for_gen)
    end

    return results
end

function extract_measurements(
    ecosystem_id::String, species_id::String, metric::String, submetric::String,
    generations::UnitRange{Int}
)
    measurements_per_trial = Dict{Int, Vector{Float64}}()

    # Assuming trial naming is sequential like "ecosystem_id-1.jld2", "ecosystem_id-2.jld2", ...
    trial_id = 1
    while true
        jld2_file_path = "trials/$ecosystem_id/$trial_id.jld2"
        
        # Stop when we can't find more trials
        if !isfile(jld2_file_path)
            break
        end
        file = JLD2.jldopen(jld2_file_path, "r")
        
        for gen in generations
            submetric_value = load_submetric_value(file, gen, species_id, metric, submetric)
            # Accumulate values for each generation
            push_or_add!(measurements_per_trial, trial_id, submetric_value)
        end
        close(file)

        trial_id += 1
    end
    # println("measurements_per_trial: ", measurements_per_trial)
    measurements_per_gen = process_measurements(measurements_per_trial)

    # Convert to a vector of BasicStatisticalMeasurements
    return measurements_per_gen
end


function plot_measurements(
    ecosystem_id::String, species_ids::Vector{String}, metric::String, submetric::String,
    generations::UnitRange{Int}
)
    p = plot()  # Initialize an empty plot
    
    for species_id in species_ids
        measurements = extract_measurements(ecosystem_id, species_id, metric, submetric, generations)

        # Extract mean, lower_confidence, and upper_confidence for plotting
        means = [m.mean for m in measurements]
        lower = [m.lower_confidence for m in measurements]
        upper = [m.upper_confidence for m in measurements]
        println("------")
        println(upper)
        println(means)
        println(lower)

        ribbon_below = means .- lower
        ribbon_above = upper .- means
        plot!(
            p, 
            generations, 
            means, 
            ribbon=(ribbon_below, ribbon_above), 
            label="", fillalpha=0.3, color=:auto, linewidth = 3)  # Plot ribbon without label
        #plot!(p, generations, means, label=species_id, linewidth=3, color=:auto)  # Overlay with line
    end

    # Set plot title, labels, and legend
    title!(p, "Metric: $metric, Submetric: $submetric for Ecosystem $ecosystem_id")
    xlabel!(p, "Generation")
    ylabel!(p, "Value")
    display(p)
end

function measurements_to_dataframe(
    ecosystem_id::String, species_ids::Vector{String}, metric::String, submetric::String,
    generations::UnitRange{Int}
)
    # Create an empty DataFrame with the desired columns
    df = DataFrame(
        species_id=String[],
        generation=Int[],
        mean=Float64[],
        lower_confidence=Float64[],
        upper_confidence=Float64[]
    )

    for species_id in species_ids
        measurements = extract_measurements(ecosystem_id, species_id, metric, submetric, generations)
        
        for gen in generations
            measurement = measurements[gen]
            push!(
                df,
                Dict(
                    :species_id => species_id,
                    :generation => gen,
                    :mean => measurement.mean,
                    :lower_confidence => measurement.lower_confidence,
                    :upper_confidence => measurement.upper_confidence
                )
            )
        end
    end
    
    return df
end

function dispatch_measurements_to_dataframe(
    ecosystem_id::String,
    generations::UnitRange{Int},
    species_ids::Vector{String} = ["Host", "Parasite", "Mutualist"],
    metrics::Vector{String} = ["GenotypeSize", "MinimizedGenotypeSize", "AllSpeciesFitness"],
    submetric::String = "mean"
)
    # Iterate over each species and metric combination
    for species in species_ids
        for metric in metrics
            # Extract aggregated measurements and store in a DataFrame
            df = measurements_to_dataframe(ecosystem_id, [species], metric, submetric, generations)

            # Create a unique filename for the DataFrame based on species and metric
            filename = "results_$(species)_$(metric)_$(submetric).csv"
            
            # Save the DataFrame to a .csv file
            CSV.write(filename, df)

            println("Saved measurements for species '$species' and metric '$metric' to $filename.")
        end
    end
end


function plot_csv_results(
    data_dir_path::String;
    species_ids::Vector{String} = ["Host", "Parasite", "Mutualist"],
    metrics::Vector{String} = ["GenotypeSize", "MinimizedGenotypeSize", "AllSpeciesFitness"],
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
        p = plot(ylim=y_limits[i], 
                 legend=legend, title="$(plot_title_prefix) $(metric)")

        for (idx, species) in enumerate(species_ids)
            filename = "$data_dir_path/results_$(species)_$(metric)_$(submetric).csv"

            if isfile(filename)
                df = CSV.read(filename, DataFrame)
                
                # Extract generations, means, lower_confidence, and upper_confidence for plotting
                generations = df[:, :generation]
                means = df[:, :mean]
                lower = df[:, :lower_confidence]
                upper = df[:, :upper_confidence]

                ribbon_below = means .- lower
                ribbon_above = upper .- means

                color_choice = idx <= length(colors) ? colors[idx] : :auto

                # Plot data with ribbon
                plot!(
                    p, 
                    generations, 
                    means, 
                    ribbon=(ribbon_below, ribbon_above), 
                    label = species, 
                    fillalpha = 0.3, 
                    color = color_choice, 
                    linewidth = linewidth,
                    legend = :topleft
                )
            else
                println("File $filename not found!")
            end
        end

        # Set labels and save the plot
        xlabel!(p, x_labels[i])
        ylabel!(p, y_labels[i])
        savefig(p, "$(file_prefix)$(metric).png")
    end
end
# Example usage:
#dispatch_measurements_to_dataframe(ecosystem_id, 1:10)

# archive_path = "trials/test/1.jld2"
# ecosystem_id = "test"
# species_id = "Host"
# metric = "GenotypeSize"
# submetric = "mean"
# gen = 10

#measurements = extract_measurements(ecosystem_id, species_id, metric, submetric, 1:gen)
# println(measurements)
# load_submetric_value(archive_path, gen, species_id, metric, submetric)

#plot_measurements(ecosystem_id, ["Host", "Mutualist", "Parasite"], "GenotypeSize", "mean", 1:10)
# df = measurements_to_dataframe(ecosystem_id, ["Host", "Mutualist", "Parasite"], "GenotypeSize", "mean", 1:10)
# println(df)
