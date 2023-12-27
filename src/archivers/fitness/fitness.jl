module Fitness

export FitnessArchiver

import ...Archivers: archive!

using HDF5: h5open
using ...Species: AbstractSpecies, get_population_genotypes, get_minimized_population_genotypes
using ...Archivers: Archiver
using ...Archivers.Utilities: get_aggregate_measurements, add_measurements_to_hdf5
using ...Genotypes: get_size
using ...Abstract.States: State, get_all_species, get_generation, get_evaluations
using ...Evaluators: Evaluation

function measure_fitness(evaluation::Evaluation)
    fitnesses = Dict(string(record.id) => record.fitness for record in evaluation.records)
    aggregate_measurements = get_aggregate_measurements(collect(values(fitnesses)))
    #fitness = Dict("all" => aggregate_measurements, "by_id" => fitnesses)
    fitness = Dict("all" => aggregate_measurements)
    return fitness
end

function measure_fitness(evaluations::Vector{<:Evaluation})
    fitnesses = Dict(evaluation.id => measure_fitness(evaluation) for evaluation in evaluations)
    return fitnesses
end

measure_fitness(state::State) = measure_fitness(get_evaluations(state))

struct FitnessArchiver <: Archiver
    archive_interval::Int
    h5_path::String
end

function archive!(archiver::FitnessArchiver, state::State)
    generation = get_generation(state)
    do_not_archive = archiver.archive_interval == 0
    is_archive_interval = get_generation(state) == 1 ||
        get_generation(state) % archiver.archive_interval == 0
    if do_not_archive || !is_archive_interval
        return
    end
    file = h5open(archiver.h5_path, "r+")
    base_path = "generations/$generation/fitness"
    fitnesses = measure_fitness(state)
    add_measurements_to_hdf5(file, base_path, fitnesses)
    #println("fitnesses: ", fitnesses)
    for (id, measurements) in fitnesses
        mean_value    = round(measurements["all"]["mean"]; digits = 3)
        maximum_value = round(measurements["all"]["maximum"]; digits = 3)
        minimum_value = round(measurements["all"]["minimum"]; digits = 3)
        std_value     = round(measurements["all"]["std"]; digits = 3)
        println("fitness_$id: mean: $mean_value, min: $minimum_value, max: $maximum_value, std: $std_value)")
    end
    #Print the mean, min, max, and std of the fitnesses for each evaluation
    close(file)
end

end