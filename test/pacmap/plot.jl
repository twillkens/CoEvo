using Plots
using CoEvo
using Serialization
using DataFrames
using CSV
using CoEvo.Abstract
using PyCall

function load_population(
    data_dir::String, task::String, condition::String, trial::Int, generation::Int, species::String
)
    path = "$data_dir/$task/$condition/$trial/$species/$generation.jls"
    population = deserialize(path)
    return population
end

function initialize_df(n_dims::Int)
    # Base columns
    columns = [
        :task => String[],
        :condition => String[],
        :trial => Int[],
        :generation => Int[],
        :species => String[],
        :id => Int[],
        :parent_id => Int[]
    ]
    
    # Add dimension columns based on n_dims
    for dim in 1:n_dims
        push!(columns, Symbol("dim_$dim") => Float64[])
    end
    
    # Create and return the DataFrame
    df = DataFrame(columns)
    return df
end

function update_df!(
    df::DataFrame, 
    individual::Individual, 
    task::String,
    condition::String,
    trial::Int,
    generation::Int, 
    species::String
)
    genes = individual.genotype.genes
    info = Dict(
        :task => task,
        :condition => condition,    
        :trial => trial,
        :generation => generation, 
        :species => species,
        :id => individual.id, 
        :parent_id => individual.parent_id
    )
    
    for (i, gene) in enumerate(genes)
        info[Symbol("dim_$i")] = gene
    end
    
    push!(df, info)
end

function make_line!(
    df::DataFrame, 
    task::String,
    condition::String,
    trial::Int,
    species::String,
    max_grow::Float64,
    n_dims::Int,
    dims_to_grow::Vector{Symbol} 
)
    if length(dims_to_grow) > n_dims
        error("The number of dimensions to grow exceeds the total number of dimensions")
    end
    n_generations = 10_000
    
    # Get the maximum id in the DataFrame to start new ids after the existing ones
    max_id = maximum(df.id)
    
    for generation in 1:n_generations
        growth = (generation / n_generations) * max_grow
        new_individual = Dict(
            :task => task,
            :condition => condition,
            :trial => trial,
            :generation => generation,
            :species => species,
            :id => max_id + generation,
            :parent_id => 0
        )
        
        for dim in 1:n_dims
            if Symbol("dim_$dim") in dims_to_grow
                new_individual[Symbol("dim_$dim")] = growth
            else
                new_individual[Symbol("dim_$dim")] = 0.0
            end
        end
        
        push!(df, new_individual)
    end
    
    return df
end

function make_randoms!(
    df::DataFrame, 
    task::String,
    condition::String,
    trial::Int,
    max_id::Int, 
    max_val::Float64, 
    n_randoms::Int, 
    n_dims::Int
)
    for i in 1:n_randoms
        max_id += 1
        new_individual = Dict(
            :task => task,
            :condition => condition,
            :trial => trial,
            :generation => 0,
            :species => "random",
            :id => max_id,
            :parent_id => 0
        )
        
        # Assign random values uniformly from (0, max_val) for each dimension
        for dim in 1:n_dims
            new_individual[Symbol("dim_$dim")] = rand() * max_val
        end
        
        push!(df, new_individual)
    end
end

function save_trial_populations_to_csv(
    data_dir::String,
    task::String,
    condition::String,
    generations::Int, 
    n_dims::Int,
    trial_range::UnitRange{Int}
)
    df = initialize_df(n_dims)
    max_id = 0
    max_val = 0.0
    for trial in trial_range
        println("Trial: $trial")
        #df = initialize_df(n_dims)
        
        for species in ["learner_population", "test_population"]
            for generation in 1:generations
                population = load_population(data_dir, task, condition, trial, generation, species)
                for individual in population
                    update_df!(df, individual, task, condition, trial, generation, species)
                    if individual.id > max_id
                        max_id = Int64(individual.id)
                    end
                    ind_val = findmax(individual.genotype.genes)[1]
                    if ind_val > max_val
                        max_val = ind_val
                        #println("new max:", max_val)
                        #println(generation, individual)
                    end
                end
            end
        end
        
        #make_randoms!(df, max_id, max_val, 100_000, n_dims)
    end
    # Create a fully optimal line growing in all dimensions
    optimal_dims = [Symbol("dim_$i") for i in 1:n_dims]
    make_line!(df, task, condition, -1, "line_optimal", max_val, n_dims, optimal_dims)
    
    # Create lines each growing in only one dimension
    for i in 1:n_dims
        make_line!(df, task, condition, -1, "line_$i", max_val, n_dims, [Symbol("dim_$i")])
    end
    csv_path = "$data_dir/$task/$condition/combined_pops.csv"
    
    CSV.write(csv_path, df)
end


using StatsBase

function reduce_dimensions_with_pacmap(
    data_dir::String, task::String, condition::String, trial::Int, n_samples::Int
)
    # Read the CSV file
    file_path = "$data_dir/$task/$condition/combined_pops.csv"
    df = CSV.read(file_path, DataFrame)
    
    # Automatically identify reduction columns based on "dim" in the name
    reduction_columns = filter(col -> occursin("dim", String(col)), names(df))
    
    # Identify the columns to keep intact
    intact_data = df[:, Not(reduction_columns)]
    
    # Select the rows to be reduced (only the specified trial)
    reduce_data_trial = df[df.trial .== trial, reduction_columns]
    
    # Select rows of species with "line" in the name
    reduce_data_line_species = df[occursin.("line", df.species), reduction_columns]
    
    # Select random rows from other trials, excluding "line" species
    other_trials_data = df[(df.trial .!= trial) .& .!occursin.("line", df.species), :]
    sample_indices = sample(1:nrow(other_trials_data), n_samples, replace=false)
    sampled_other_data = other_trials_data[sample_indices, reduction_columns]
    
    # Combine the trial data, "line" species data, and sampled other trial data
    combined_reduce_data = vcat(reduce_data_trial, reduce_data_line_species, sampled_other_data)
    
    # Convert the columns to be reduced into a matrix
    data_matrix = Matrix(combined_reduce_data)
    
    # Import the pacmap package
    pacmap = pyimport("pacmap")
    
    # Initialize PaCMAP
    emb = pacmap.PaCMAP(n_components = 2, verbose=true)
    
    # Fit and transform the data
    reduced_data = emb.fit_transform(data_matrix, init="pca" )
    
    # Convert the reduced data back to a DataFrame
    reduced_df = DataFrame(reduced_data, [:dim1, :dim2])
    
    # Combine the intact data with the reduced data
    final_intact_data = vcat(
        intact_data[df.trial .== trial, :], 
        intact_data[occursin.("line", df.species), :], 
        intact_data[sample_indices, :]
    )
    final_df = hcat(final_intact_data, reduced_df)
    
    # Save the final DataFrame to a new CSV file
    output_file_path = replace(file_path, r"\.csv$" => "_pacmap_$trial.csv")
    CSV.write(output_file_path, final_df)
    
    println("Reduced data saved to: $output_file_path")
end


using CSV
using DataFrames
using Plots

function load_learners(file_path::String)
    CSV.read(file_path, DataFrame)
end

function get_species_with_line(df::DataFrame)
    unique_species = unique(df.species)
    return filter(species -> occursin("line", species), unique_species)
end


function make_animation(
    data_dir::String, task::String, condition::String, trial::Int, n_generations::Int=500
)
    #file_path = "$data_dir/$task/$condition/combined_pops_pacmap_$trial.csv"
    file_path = "$data_dir/$task/$condition/combined_pops.csv"
    df = load_learners(file_path)
    species_with_line = get_species_with_line(df)
    colors = [:blue, :red, :green, :purple, :orange, :brown, :pink, :gray, :cyan, :magenta]
    
    anim = @animate for generation in 1:n_generations
        println("Generation: $generation")
        println("Species_with_line: $species_with_line")
        generation_data = filter(row -> row.generation == generation, df)
        
        # Filter for learner_population and test_population of the specified trial
        learner_population = filter(row -> row.species == "learner_population" && row.trial == trial, generation_data)
        test_population = filter(row -> row.species == "test_population" && row.trial == trial, generation_data)
        
        # Extract genotypes for learner and test populations
        learner_X = learner_population.dim_1
        learner_Y = learner_population.dim_2
        test_X = test_population.dim_1
        test_Y = test_population.dim_2
        
        # Plot the learners and test population as points on a 2D plane
        scatter(
            learner_X, learner_Y, label="Learners", xlim=(-1, 7), ylim=(-1, 7), 
            xlabel="Gene 1", ylabel="Gene 2", title="Generation $generation", color=:blue,
            legend=:topright, size = (1200, 800)
        )
        scatter!(test_X, test_Y, label="Tests", color=:red)
        
        # Plot all members of species with "line" in their name
        for (i, species) in enumerate(species_with_line)
            line_population = filter(row -> row.species == species, df)
            line_population = line_population[1:10:end, :]
            line_X = line_population.dim_1
            line_Y = line_population.dim_2
            plot!(line_X, line_Y, label=species, color=colors[mod1(i, length(colors))], lw=2)
        end
    end

    # Save the animation as a GIF file
    gif_name = "$task-$condition-$trial-animation.gif"
    gif(anim, gif_name, fps=10)
end


# Example usage
#make_animation("test/pacmap/pacmap_data/coo_hard-cfs_qmeu_slow-1/combined_pops_pacmap.csv")

#function make_animation(data_dir::String, task::String, condition::String, trial::Int)
#    df = load_learners(file_path)
#    species_with_line = get_species_with_line(df)
#    colors = [:blue, :red, :green, :purple, :orange, :brown, :pink, :gray, :cyan, :magenta]
#    
#    anim = @animate for generation in 1:500
#        println("Generation: $generation")
#        println("Species_with_line: $species_with_line")
#        generation_data = filter(row -> row.generation == generation, df)
#        
#        # Filter for learner_population and test_population
#        learner_population = filter(row -> row.species == "learner_population", generation_data)
#        test_population = filter(row -> row.species == "test_population", generation_data)
#        
#        # Extract genotypes for learner and test populations
#        learner_X = learner_population.dim1
#        learner_Y = learner_population.dim2
#        test_X = test_population.dim1
#        test_Y = test_population.dim2
#        
#        # Plot the learners and test population as points on a 2D plane
#        scatter(
#            learner_X, learner_Y, label="Learner Population", xlim=(-40, 40), ylim=(-40, 40), 
#            xlabel="Gene 1", ylabel="Gene 2", title="Generation $generation", color=:blue
#        )
#        scatter!(test_X, test_Y, label="Test Population", color=:red)
#        
#        # Plot all members of species with "line" in their name
#        for (i, species) in enumerate(species_with_line)
#            line_population = filter(row -> row.species == species, df)
#            line_X = line_population.dim1
#            line_Y = line_population.dim2
#            plot!(line_X, line_Y, label=species, color=colors[mod1(i, length(colors))], lw=2)
#        end
#    end
#
#    # Save the animation as a GIF file
#    gif(anim, "$(splitext(basename(file_path))[1])-animation.gif", fps=10)
#end