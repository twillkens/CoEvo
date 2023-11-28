using ..Names
using ..Genotypes.FunctionGraphs
using ..Ecosystems.Basic: BasicEcosystem

function load_genotype(genotype_group::JLD2.Group)
    # Load node id lists directly.
    input_node_ids = genotype_group["input_node_ids"]
    bias_node_ids = genotype_group["bias_node_ids"]
    hidden_node_ids = genotype_group["hidden_node_ids"]
    output_node_ids = genotype_group["output_node_ids"]
    n_nodes_per_output = genotype_group["n_nodes_per_output"]
    
    # Load node-related data.
    node_ids = genotype_group["node_ids"]
    node_functions = genotype_group["node_functions"]
    
    # Initialize an empty nodes dictionary.
    nodes = Dict{Int, FunctionGraphNode}()
    for (id, func) in zip(node_ids, node_functions)
        nodes[id] = FunctionGraphNode(id, func, FunctionGraphConnection[])
    end
    
    # Load connection data and establish connections.
    connection_data = genotype_group["connection_data"]
    for (node_id, input_id, weight, is_recurrent) in connection_data
        connection = FunctionGraphConnection(input_id, weight, is_recurrent)
        push!(nodes[node_id].input_connections, connection)
    end
    
    # Construct and return the FunctionGraphGenotype.
    genotype = FunctionGraphGenotype(
        input_node_ids=input_node_ids,
        bias_node_ids=bias_node_ids,
        hidden_node_ids=hidden_node_ids,
        output_node_ids=output_node_ids,
        nodes=nodes,
        n_nodes_per_output=n_nodes_per_output
    )
    return genotype
end

function load_individual(individual_id::Int, individual_group::JLD2.Group)
    genotype = load_genotype(individual_group["genotype"])
    parent_ids = individual_group["parent_ids"]
    individual = BasicIndividual(individual_id, genotype, parent_ids)
    return individual
end


function load_population!(
    jld2_file::JLD2.JLDFile, 
    gen::Int, 
    species_id::String,
    pop_ids::Set{Int},
    population::Vector{<:Individual}
)
    children_group = jld2_file["individuals/$gen/$species_id/children"]
    for individual_id_str in keys(children_group) 
        individual_id = parse(Int, individual_id_str)
        if individual_id in pop_ids
            individual_group = children_group[individual_id_str]
            individual = load_individual(individual_id, individual_group)
            push!(population, individual)
            delete!(pop_ids, individual_id)
        end
    end
    if length(pop_ids) == 0
        return population
    elseif gen == 1
        error("Could not find all individuals in population")
    else
        prev_gen = gen - 1
        # Recursive call to get the previous generation's individuals
        return load_population!(
            jld2_file, prev_gen, species_id, pop_ids, population
        )
    end
end

function load_species(jld2_file::JLD2.JLDFile, gen::Int, species_id::String)
    species_path = "individuals/$gen/$species_id"
    children_group = jld2_file["$species_path/children"]
    children = Dict{Int, Individual}()
    children = map(keys(children_group)) do individual_id_str
        individual_id = parse(Int, individual_id_str)
        individual_group = children_group[individual_id_str]
        individual = load_individual(individual_id, individual_group)
        return individual
    end
    
    if gen > 1
        pop_ids = Set(jld2_file["$species_path/population_ids"])
        prev_gen = gen - 1
        population = empty(children)
        population = load_population!(jld2_file, prev_gen, species_id, pop_ids, population)
    else
        population = copy(children)
    end
    
    return BasicSpecies(species_id, population, children)
end

function load_ecosystem(;
    path::String = "/media/tcw/Seagate/two_comp_1/1.jld2", 
    gen::Int = 10,
)
    #println("Loading generation $gen")
    
    jld2_file = jldopen(path, "r")
    base_path = "individuals/$gen"
    
    all_species = [
        load_species(jld2_file, gen, species_id) 
        for species_id in sort(collect(keys(jld2_file[base_path])))
    ]
    
    close(jld2_file)
    
    return BasicEcosystem("gen_$gen", all_species)
end

function load_ecosystem(file::JLD2.JLDFile, gen::Int)
    base_path = "individuals/$gen"
    all_species = [
        load_species(file, gen, species_id) 
        for species_id in sort(collect(keys(file[base_path])))
    ]
    return BasicEcosystem("gen_$gen", all_species)
end
