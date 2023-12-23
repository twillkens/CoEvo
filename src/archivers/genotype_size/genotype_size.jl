module GenotypeSize

export GenotypeSizeArchiver

import ...Archivers: archive!

using HDF5: h5open
using ...Species: AbstractSpecies, get_population, get_population_genotypes
using ...Archivers: Archiver
using ...Archivers.Utilities: get_aggregate_measurements, add_measurements_to_hdf5
using ...Genotypes: get_size, minimize
using ...Abstract.States: State, get_all_species, get_generation

function measure_genotype_size(species::AbstractSpecies; do_minimize::Bool = false)
    sizes = do_minimize ? Dict(
        string(individual.id) => get_size(minimize(individual.genotype)) 
        for individual in get_population(species)
    ) : Dict(
        string(individual.id) => get_size(individual.genotype) 
        for individual in get_population(species)
    )
    aggregate_measurements = get_aggregate_measurements(collect(values(sizes)))
    sizes = Dict("aggregate" => aggregate_measurements, "by_id" => sizes)
    sizes = Dict(species.id => sizes)
    return sizes
end

function measure_genotype_size(
    all_species::Vector{<:AbstractSpecies}; do_minimize::Bool = false
)
    all_genotypes = get_population_genotypes(all_species)
    all_sizes = do_minimize ? Dict(
        "aggregate" => get_aggregate_measurements(
            [get_size(minimize(genotype)) for genotype in all_genotypes])
    ) : Dict(
        "aggregate" => get_aggregate_measurements(
            [get_size(genotype) for genotype in all_genotypes])
    )
    species_genotype_sizes = merge(
        [measure_genotype_size(species) for species in all_species]...
    )
    size_key = do_minimize ? "minimized" : "full"
    sizes = Dict(size_key => merge(all_sizes, species_genotype_sizes))
    return sizes
end

function measure_genotype_size(state::State)
    all_species = get_all_species(state)
    genotype_size = measure_genotype_size(all_species)
    return genotype_size
end

struct GenotypeSizeArchiver <: Archiver
    archive_interval::Int
    h5_path::String
end

function archive!(archiver::GenotypeSizeArchiver, state::State)
    generation = get_generation(state)
    if archiver.archive_interval == 0 || generation % archiver.archive_interval != 0
        return
    end
    file = h5open(archiver.h5_path, "r+")
    base_path = "generations/$generation/genotype_size"
    genotype_sizes = measure_genotype_size(state; do_minimize = false)
    minimized_genotype_sizes = measure_genotype_size(state; do_minimize = true)
    sizes = merge(genotype_sizes, minimized_genotype_sizes)
    add_measurements_to_hdf5(file, base_path, sizes)
    close(file)
end

end