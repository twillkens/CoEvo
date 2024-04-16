export create_archivers, NumbersGameArchiver, archive!, collect_species_data, append_to_csv
export calculate_average_minimum_gene, calculate_num_max_gene_at_index, calculate_average_gene_value_at_index

using DataFrames
using CSV
using ....Abstract
using Serialization

struct NumbersGameArchiver <: Archiver 
    data::DataFrame
end

function get_save_file(configuration::MaxSolveConfiguration)
    task = configuration.task
    algo = configuration.test_algorithm
    domain = configuration.domain
    tag = configuration.tag
    file = "$(task)-$(algo)-$(domain)-$(tag).csv"
    return file
end

function NumbersGameArchiver(configuration::MaxSolveConfiguration)
    save_file = get_save_file(configuration)
    if isfile(save_file)
        data = CSV.read(save_file, DataFrame)
    else
        data = DataFrame(
            trial = Int[], 
            algorithm = String[],
            generation = Int[], 
            fitness = Float64[], 
            score = Float64[], 
            seed = Int[]
        )
    end
    return NumbersGameArchiver(data)
end

function calculate_average_minimum_gene(individuals::Vector{<:Individual})
    total_minimum_gene = 0.0
    #println("---")
    for individual in individuals
        total_minimum_gene += minimum(individual.genotype.genes)
        #print(round.(individual.genotype.genes, digits=3), ", ")
    end
    avg_minimum_gene = length(individuals) > 0 ? total_minimum_gene / length(individuals) : 0.0
    return round(avg_minimum_gene, digits=3)
end

function calculate_num_max_gene_at_index(individuals::Vector{<:Individual}, index::Int)
    num_max_gene = 0
    for individual in individuals
        if argmax(individual.genotype.genes) == index
            num_max_gene += 1
        end
    end
    return num_max_gene
end

function calculate_average_gene_value_at_index(individuals::Vector{<:Individual}, index::Int)
    total_gene_value = 0.0
    for individual in individuals
        total_gene_value += individual.genotype.genes[index]
    end
    avg_gene_value = length(individuals) > 0 ? total_gene_value / length(individuals) : 0.0
    return round(avg_gene_value, digits=3)
end

function collect_species_data(
    species_id::String, population::Vector{<:Individual}, generation::Int
)
    data_row = DataFrame()
    data_row[!, :generation] = [generation]
    data_row[!, :species_id] = [species_id]

    println("------------")
    println("Generation $generation, Species ID $(species_id)")
    length_genotype = length(population[1].genotype.genes)

    for i in 1:length_genotype
        max_index = calculate_num_max_gene_at_index(population, i)
        avg_value = calculate_average_gene_value_at_index(population, i)
        data_row[!, Symbol("maxindex_$i")] = [max_index]
        data_row[!, Symbol("avgvalue_$i")] = [avg_value]

        println("Max Index $i: $max_index, Avg Value $i: $avg_value")
    end

    avg_min_gene = calculate_average_minimum_gene(population)
    data_row[!, :avgmin_gene] = [avg_min_gene]

    println("Average Minimum Gene: $avg_min_gene")
    println("------------")

    return data_row
end

function append_to_csv(df, csv_path)
    if isfile(csv_path)
        existing_df = CSV.read(csv_path, DataFrame)
        append!(existing_df, df)
        CSV.write(csv_path, existing_df)
    else
        CSV.write(csv_path, df)
    end
end

function archive!(archiver::NumbersGameArchiver, state::State)
    #all_data = DataFrame()
    species_data = collect_species_data("L", state.ecosystem.learner_population, state.generation)
    species_data = collect_species_data("T", state.ecosystem.test_population, state.generation)
    elite_fitness = -1
    elite = nothing
    for learner in [state.ecosystem.learner_population ; state.ecosystem.learner_children]
        p = state.ecosystem.payoff_matrix
        fitness = sum(p[learner.id, :])
        if fitness > elite_fitness
            elite_fitness = fitness
            elite = learner
        end
    end
    elite_minimum_gene = minimum(elite.genotype.genes)
    info = (
        trial = state.configuration.id, 
        algorithm = state.configuration.test_algorithm,
        generation = state.generation, 
        fitness = elite_fitness,
        score = elite_minimum_gene,
        seed = state.configuration.seed
    )
    push!(archiver.data, info)
    CSV.write(get_save_file(state.configuration), archiver.data)
end
