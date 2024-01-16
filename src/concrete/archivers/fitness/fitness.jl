module Fitness

export FitnessArchiver

import ....Interfaces: archive!

using DataFrames
using CSV
using ....Abstract
using ....Interfaces
using ...Archivers.Utilities: get_aggregate_measurements

function measure_fitness(evaluation::Evaluation)
    fitnesses = Dict(string(record.id) => record.fitness for record in evaluation.records)
    aggregate_measurements = get_aggregate_measurements(collect(values(fitnesses)))
    return aggregate_measurements
end

function measure_fitness(evaluations::Vector{<:Evaluation})
    fitnesses = Dict(evaluation.id => measure_fitness(evaluation) for evaluation in evaluations)
    return fitnesses
end

struct FitnessArchiver <: Archiver end

function archive!(::FitnessArchiver, state::State)
    fitnesses = measure_fitness(state.evaluations)
    records = []
    for (id, measurements) in fitnesses
        mean_value    = round(measurements["mean"]; digits = 3)
        maximum_value = round(measurements["maximum"]; digits = 3)
        minimum_value = round(measurements["minimum"]; digits = 3)
        std_value     = round(measurements["std"]; digits = 3)
        println("fitness_$id: mean: $mean_value, min: $minimum_value, max: $maximum_value, std: $std_value)")
        record = merge(Dict("id" => id, "generation" => state.generation), measurements)
        push!(records, record)
    end
    if isempty(records)
        return
    end
    archive_directory = state.configuration.archive_directory
    csv_path = "$(archive_directory)/fitnesses.csv"
    # Convert records to a DataFrame
    df = DataFrame(records)

    # Check if the CSV file exists
    if isfile(csv_path)
        # Read existing CSV and append new data
        existing_df = CSV.read(csv_path, DataFrame)
        append!(existing_df, df)
        CSV.write(csv_path, existing_df)
    else
        # Create a new CSV file with the current data
        CSV.write(csv_path, df)
    end
end

end