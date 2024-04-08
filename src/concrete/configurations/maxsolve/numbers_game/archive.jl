export create_archivers, NumbersGameArchiver, archive!, collect_species_data, append_to_csv
export calculate_average_minimum_gene, calculate_num_max_gene_at_index, calculate_average_gene_value_at_index

using DataFrames
using CSV
using Serialization

struct NumbersGameArchiver <: Archiver end

function calculate_average_minimum_gene(individuals::Vector{<:Individual})
    total_minimum_gene = 0.0
    for individual in individuals
        total_minimum_gene += minimum(individual.genotype.genes)
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

function collect_species_data(species, generation)
    data_row = DataFrame()
    data_row[!, :generation] = [generation]
    data_row[!, :species_id] = [species.id]

    println("------------")
    println("Generation $generation, Species ID $(species.id)")
    length_genotype = length(species.population[1].genotype.genes)

    for i in 1:length_genotype
        max_index = calculate_num_max_gene_at_index(species.population, i)
        avg_value = calculate_average_gene_value_at_index(species.population, i)
        data_row[!, Symbol("maxindex_$i")] = [max_index]
        data_row[!, Symbol("avgvalue_$i")] = [avg_value]

        println("Max Index $i: $max_index, Avg Value $i: $avg_value")
    end

    avg_min_gene = calculate_average_minimum_gene(species.population)
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

function archive!(::NumbersGameArchiver, state::State)
    #all_data = DataFrame()
    for species in state.ecosystem.all_species
        species_data = collect_species_data(species, state.generation)
        #append!(all_data, species_data)
    end
    #mode = state.configuration.mode
    #csv_dir = "trials/$mode"
    #if !isdir(csv_dir)
    #    mkpath(csv_dir)
    #end
    #csv_path = "$csv_dir/$(state.id).csv"
    #append_to_csv(all_data, csv_path)
end


function create_archivers(::NumbersGameExperimentConfiguration)
    archivers = [NumbersGameArchiver()]
    return archivers
end
    #println("--Generation $(state.generation)--\n")
    #for learner in new_learner_archive
    #    genes = round.(learner.genotype.genes, digits=3)
    #    print("learner_$(learner.id) = $genes, ")
    #end
    #println("--")
    #println("length_test_archive = ", length(new_test_archive), "\n")
    #for test in new_test_archive
    #    genes = round.(test.genotype.genes, digits=3)
    #    print("test_$(test.id) = $genes, ")
    #end
    #println()