module GenotypeSize

export GenotypeSizeArchiver

using DataFrames
using CSV
import ....Interfaces: archive!
using ....Abstract
using ....Interfaces
using ...Archivers.Utilities


function measure_genotype_size(species::AbstractSpecies, do_minimize::Bool = false)
    sizes = [
        get_size(do_minimize ? individual.minimized_genotype : individual.full_genotype) 
        for individual in species.population]
    return get_aggregate_measurements(sizes)
end

function measure_genotype_size(ecosystem::Ecosystem; do_minimize::Bool = false)
    sizes = Dict(
        species.id => measure_genotype_size(species; do_minimize = do_minimize) 
        for species in ecosystem.all_species
    )
    return sizes
end

function measure_genotype_size(state::State; do_minimize::Bool = false)
    all_species = [species for species in state.ecosystem.species]
    genotype_size = measure_genotype_size(all_species; do_minimize = do_minimize)
    return genotype_size
end

struct GenotypeSizeArchiver <: Archiver
end

# Function to print genotype sizes
function print_genotype_sizes(genotype_sizes, prefix)
    for (id, measurements) in genotype_sizes
        mean_value    = round(measurements["mean"]; digits = 3)
        maximum_value = round(measurements["maximum"]; digits = 3)
        minimum_value = round(measurements["minimum"]; digits = 3)
        std_value     = round(measurements["std"]; digits = 3)
        println("$(prefix)_genotype_size_$id: mean: $mean_value, min: $minimum_value, max: $maximum_value, std: $std_value)")
    end
end

# Function to archive genotype sizes to CSV
function archive_to_csv(genotype_sizes, archive_directory, file_name, generation)
    records = []
    for (id, measurements) in genotype_sizes
        record = merge(Dict("id" => id, "generation" => generation), measurements)
        push!(records, record)
    end

    if isempty(records)
        return
    end

    csv_path = "$(archive_directory)/$(file_name)"
    df = DataFrame(records)
    if isfile(csv_path)
        existing_df = CSV.read(csv_path, DataFrame)
        append!(existing_df, df)
        CSV.write(csv_path, existing_df)
    else
        CSV.write(csv_path, df)
    end
end

function archive!(::GenotypeSizeArchiver, state::State)
    full_genotype_sizes = measure_genotype_size(state; do_minimize = false)
    print_genotype_sizes(full_genotype_sizes, "full")
    archive_to_csv(full_genotype_sizes, state.archive_directory, "full_genotype_size.csv", state.generation)

    minimized_genotype_sizes = measure_genotype_size(state; do_minimize = true)
    print_genotype_sizes(minimized_genotype_sizes, "minimized")
    archive_to_csv(minimized_genotype_sizes, state.archive_directory, "minimized_genotype_size.csv", state.generation)
end

end