module FunctionGraphMutators

export FunctionGraphMutator, add_function, remove_function, swap_function
export redirect_connection, identity, inject_noise!, ConnectionRedirectionSpecification

using Random: rand, randn, AbstractRNG
using StatsBase: sample, Weights
using ....Genotypes.FunctionGraphs: FunctionGraphGenotype, FunctionGraphNode
using ....Genotypes.FunctionGraphs: FunctionGraphConnection, GraphFunction, FUNCTION_MAP
using .....Ecosystems.Utilities.Counters: Counter, next!
using ...Mutators.Abstract: Mutator

import ....Species.Mutators.Interfaces: mutate
import Base: identity

@kwdef struct ConnectionRedirectionSpecification
    node_id::Int
    input_connection_index::Int
    new_input_node_id::Int
end

# Define equality
function Base.:(==)(a::ConnectionRedirectionSpecification, b::ConnectionRedirectionSpecification)
    return a.node_id == b.node_id &&
           a.input_connection_index == b.input_connection_index &&
           a.new_input_node_id == b.new_input_node_id
end

# Define hash
function Base.hash(a::ConnectionRedirectionSpecification, h::UInt)
    return hash(a.node_id, hash(a.input_connection_index, hash(a.new_input_node_id, h)))
end
function select_function(rng, function_map)
    potential_functions = [
        name for name in keys(function_map)
            if name ∉ [:INPUT, :BIAS, :OUTPUT]
    ]
    return rand(rng, potential_functions)
end

function create_input_connections(rng, potential_input_node_ids, arity)
    return [
        FunctionGraphConnection(
            input_node_id = rand(rng, potential_input_node_ids),
            weight = 0.0,  # or another desired method for initializing weights
            is_recurrent = true 
        ) 
        for _ in 1:arity
    ]
end

function add_function(
    rng::AbstractRNG, 
    gene_id_counter::Counter, 
    graph::FunctionGraphGenotype, 
    function_map::Dict{Symbol, GraphFunction} = FUNCTION_MAP
)
    graph = deepcopy(graph)
    new_id = next!(gene_id_counter)
    func_symbol = select_function(rng, function_map)

    potential_input_node_ids = [
        graph.input_node_ids; graph.bias_node_ids; graph.hidden_node_ids
    ]
    arity = function_map[func_symbol].arity

    input_connections = create_input_connections(rng, potential_input_node_ids, arity)
    
    new_node = FunctionGraphNode(
        id = new_id,
        func = func_symbol,
        input_connections = input_connections
    )
    graph.nodes[new_id] = new_node
    push!(graph.hidden_node_ids, new_id) 

    return graph
end


function get_nodes_with_redirected_links(
    graph::FunctionGraphGenotype, 
    node_to_delete_id::Int,
    substitutions::Vector{ConnectionRedirectionSpecification}
)
    new_nodes = Dict{Int, FunctionGraphNode}()
    for (id, node) in graph.nodes
        if id == node_to_delete_id
            continue
        end
        
        new_input_connections = copy(node.input_connections)
        
        for substitution in substitutions
            if substitution.node_id == id
                index = substitution.input_connection_index
                connection_to_change = new_input_connections[index]
                if connection_to_change.input_node_id != node_to_delete_id
                    throw(ErrorException("Cannot redirect a connection to a non-deleted node"))
                end
                new_input_connections[index] = FunctionGraphConnection(
                    input_node_id = substitution.new_input_node_id, 
                    weight = connection_to_change.weight, 
                    is_recurrent = connection_to_change.is_recurrent
                )
            end
        end
        
        new_nodes[id] = FunctionGraphNode(id, node.func, new_input_connections)
    end
    
    return new_nodes
end


function remove_function(
    genotype::FunctionGraphGenotype, 
    node_to_delete_id::Int, 
    substitutions::Vector{ConnectionRedirectionSpecification}
)
    illegal_to_remove = [
        genotype.input_node_ids ; genotype.bias_node_ids ; genotype.output_node_ids
    ]
    if node_to_delete_id in illegal_to_remove
        throw(ErrorException("Cannot remove input, bias, or output node"))
    end
    
    new_nodes = get_nodes_with_redirected_links(genotype, node_to_delete_id, substitutions)

    hidden_node_ids = filter(x -> x != node_to_delete_id, genotype.hidden_node_ids)

    genotype = FunctionGraphGenotype(
        input_node_ids = genotype.input_node_ids, 
        bias_node_ids = genotype.bias_node_ids,
        hidden_node_ids = hidden_node_ids,
        output_node_ids = genotype.output_node_ids,
        nodes = new_nodes
    )

    return genotype
end

# function get_substitutions_for_node(
#     node::FunctionGraphNode, 
#     node_id::Int, 
#     node_to_delete_id::Int, 
#     genotype::FunctionGraphGenotype, 
#     rng::AbstractRNG
# )
#     substitutions = ConnectionRedirectionSpecification[]
#     
#     for (idx, connection) in enumerate(node.input_connections)
#         if connection.input_node_id == node_to_delete_id
#             possible_redirects = filter(
#                 x -> x.input_node_id != node_to_delete_id, 
#                 genotype.nodes[node_to_delete_id].input_connections
#             )
#             new_input_node_id = isempty(possible_redirects) ? 
#                 node_id : rand(rng, [x.input_node_id for x in possible_redirects])
#             
#             push!(substitutions, ConnectionRedirectionSpecification(
#                 node_id = node_id,
#                 input_connection_index = idx,
#                 new_input_node_id = new_input_node_id
#             ))
#         end
#     end
#     
#     return substitutions
# end

function get_substitutions_for_node(
    node::FunctionGraphNode, 
    node_id::Int, 
    node_to_delete_id::Int, 
    genotype::FunctionGraphGenotype, 
    rng::AbstractRNG
)
    substitutions = ConnectionRedirectionSpecification[]
    
    for (idx, connection) in enumerate(node.input_connections)
        if connection.input_node_id == node_to_delete_id
            possible_redirects = filter(
                x -> x.input_node_id != node_to_delete_id, 
                genotype.nodes[node_to_delete_id].input_connections
            )
            
            if isempty(possible_redirects)
                # Determine if the current node is an output node
                is_output_node = node_id in genotype.output_node_ids

                if is_output_node
                    # For output nodes, choose from input, bias, and hidden nodes that are not the current node.
                    valid_nodes = setdiff(
                        union(
                            genotype.input_node_ids, 
                            genotype.bias_node_ids, 
                            genotype.hidden_node_ids
                        ), 
                        [node_id, node_to_delete_id]
                    )
                    if isempty(valid_nodes)
                        throw(ErrorException("No valid nodes to redirect to for output node"))
                    end
                    new_input_node_id = rand(rng, valid_nodes)
                else
                    # For non-output nodes, create a self-connection
                    new_input_node_id = node_id
                end
            else
                new_input_node_id = rand(rng, [x.input_node_id for x in possible_redirects])
            end
            
            push!(substitutions, ConnectionRedirectionSpecification(
                node_id = node_id,
                input_connection_index = idx,
                new_input_node_id = new_input_node_id
            ))
        end
    end
    
    return substitutions
end


function get_all_substitutions(
    genotype::FunctionGraphGenotype, 
    node_to_delete_id::Int, 
    rng::AbstractRNG
)
    substitutions = ConnectionRedirectionSpecification[]
    
    for (id, node) in genotype.nodes
        if id != node_to_delete_id
            append!(substitutions, get_substitutions_for_node(
                node, id, node_to_delete_id, genotype, rng
            ))
        end
    end
    
    return substitutions
end

function remove_function(
    rng::AbstractRNG, 
    ::Counter,
    genotype::FunctionGraphGenotype,
    ::Dict{Symbol, GraphFunction}
)
    if length(genotype.hidden_node_ids) == 0
        return deepcopy(genotype)
    end
    node_to_delete_id = rand(rng, genotype.hidden_node_ids)
    
    substitutions = get_all_substitutions(genotype, node_to_delete_id, rng)
    
    return remove_function(genotype, node_to_delete_id, substitutions)
end

"""
    select_function_with_same_arity(rng, current_function, function_map)

Select and return a new function that has the same arity as `current_function` from `function_map`.
"""
function select_function_with_same_arity(
    rng::AbstractRNG, 
    current_function::Symbol, 
    function_map::Dict{Symbol, GraphFunction}
)
    curr_arity = function_map[current_function].arity
    eligible_functions = [
        f for f in values(function_map) 
            if f.arity == curr_arity && 
                f.name != current_function && 
                f.name ∉ [:INPUT, :BIAS, :OUTPUT]
    ]
    new_function = rand(rng, eligible_functions)
    return new_function.name
end

"""
    get_genotype_after_swapping_functions(genotype, node_id, new_function)

Return a new `FunctionGraphGenotype` with the function of node `node_id` replaced by `new_function`.
"""
function get_genotype_after_swapping_functions(
    genotype::FunctionGraphGenotype, 
    node_id::Int, 
    new_function::Symbol
)
    new_nodes = deepcopy(genotype.nodes)
    new_nodes[node_id] = FunctionGraphNode(
        node_id, 
        new_function, 
        new_nodes[node_id].input_connections
    )
    genotype = FunctionGraphGenotype(
        genotype.input_node_ids, 
        genotype.bias_node_ids, 
        genotype.hidden_node_ids, 
        genotype.output_node_ids, 
        new_nodes
    )
    return genotype
end

"""
    swap_function(rng, genotype, function_map=FUNCTION_MAP)

Return a new `FunctionGraphGenotype` with the function of a randomly selected node swapped to a new function
of the same arity.
"""
function swap_function(
    rng::AbstractRNG, 
    ::Counter,
    genotype::FunctionGraphGenotype,
    function_map::Dict{Symbol, GraphFunction}
)
    if length(genotype.hidden_node_ids) == 0
        return deepcopy(genotype)
    end
    node_id = rand(rng, genotype.hidden_node_ids)
    current_function = genotype.nodes[node_id].func
    new_function = select_function_with_same_arity(rng, current_function, function_map)
    genotype = get_genotype_after_swapping_functions(genotype, node_id, new_function)
    return genotype
end

function redirect_connection(
    genotype::FunctionGraphGenotype, 
    redirection_spec::ConnectionRedirectionSpecification
)
    # Deep copy to preserve the original genotype
    new_genotype = deepcopy(genotype)

    target_node = new_genotype.nodes[redirection_spec.node_id]
    target_connection = target_node.input_connections[redirection_spec.input_connection_index]

    new_connection = FunctionGraphConnection(
        redirection_spec.new_input_node_id,
        target_connection.weight,
        target_connection.is_recurrent
    )
    target_node.input_connections[redirection_spec.input_connection_index] = new_connection

    return new_genotype
end

function redirect_connection(
    rng::AbstractRNG, 
    ::Counter,
    genotype::FunctionGraphGenotype,
    ::Dict{Symbol, GraphFunction}
)
    # Choose a random node from hidden and output nodes
    redirection_source_candidate_ids = [genotype.hidden_node_ids ; genotype.output_node_ids]
    node_id = rand(rng, redirection_source_candidate_ids)

    # Choose a random connection index to redirect
    input_connection_index = rand(rng, 1:length(genotype.nodes[node_id].input_connections))

    # Choose a random new input node from input, bias, and hidden nodes
    redirection_target_candidate_ids = [
        genotype.input_node_ids ; genotype.bias_node_ids ; genotype.hidden_node_ids
    ]
    new_input_node_id = rand(rng, redirection_target_candidate_ids)

    # Apply deterministic redirection
    redirection_spec = ConnectionRedirectionSpecification(
        node_id = node_id, 
        input_connection_index = input_connection_index, 
        new_input_node_id = new_input_node_id
    )
    genotype = redirect_connection(genotype, redirection_spec)
    return genotype
end

function identity(
    rng::AbstractRNG, ::Counter, geno::FunctionGraphGenotype, ::Dict{Symbol, GraphFunction}
)
    return deepcopy(geno)
end

function inject_noise!(genotype::FunctionGraphGenotype, noise_map::Dict{Int, Vector{Float64}})
    for (node_id, node) in genotype.nodes
        if haskey(noise_map, node_id)
            noise_values = noise_map[node_id]
            for (i, conn) in enumerate(node.input_connections)
                if i <= length(noise_values)
                    conn.weight += noise_values[i]
                end
            end
        end
    end
end

function inject_noise!(rng::AbstractRNG, genotype::FunctionGraphGenotype; std_dev::Float64=0.1)
    noise_map = Dict{Int, Vector{Float64}}()
    
    # Generating the noise_map
    for (node_id, node) in genotype.nodes
        if !isempty(node.input_connections)  # Only for nodes with connections
            noise_values = randn(rng, length(node.input_connections)) .* std_dev  # Assuming normal distribution for noise
            noise_map[node_id] = noise_values
        end
    end
    
    # Using deterministic function to inject noise
    inject_noise!(genotype, noise_map)
end

Base.@kwdef struct FunctionGraphMutator <: Mutator
    # Number of structural changes to perform per generation
    n_mutations::Int = 1
    # Uniform probability of each type of structural change
    mutation_probabilities::Dict{Function, Float64} = Dict(
        add_function => 1 / 8,
        remove_function => 1 / 8,
        swap_function => 1 / 8,
        redirect_connection => 1 / 8,
        identity => 2 / 4
    )
    noise_std::Float64 = 0.1
    function_map::Dict{Symbol, GraphFunction} = Dict(
        :IDENTITY => GraphFunction(
            name = :IDENTITY, 
            func = identity, 
            arity = 1
        ),
        :ADD => GraphFunction(
            name = :ADD, 
            func = (+), 
            arity = 2
        ),
        :SUBTRACT => GraphFunction(
            name = :SUBTRACT, 
            func = (-), 
            arity = 2
        ),
        :MULTIPLY => GraphFunction(
            name = :MULTIPLY, 
            func = (*), 
            arity = 2
        ),
        :DIVIDE => GraphFunction(
            name = :DIVIDE, 
            func = ((x, y) -> y == 0 ? 1.0 : x / y), 
            arity = 2
        ),
        :MAXIMUM => GraphFunction(
            name = :MAXIMUM, 
            func = max, 
            arity = 2
        ),
        :MINIMUM => GraphFunction(
            name = :MINIMUM, 
            func = min, 
            arity = 2
        ),
        :SIN => GraphFunction(
            name = :SIN, 
            func = (x) -> isinf(x) ? π : sin(x),
            arity = 1
        ),
        :COSINE => GraphFunction(
            name = :COSINE, 
            func = (x) -> isinf(x) ? π : cos(x),
            arity = 1
        ),
        :SIGMOID => GraphFunction(
            name = :SIGMOID, 
            func = (x -> 1 / (1 + exp(-x))), 
            arity = 1
        ),
        :TANH => GraphFunction(
            name = :TANH, 
            func = tanh, 
            arity = 1
        ),
        :RELU => GraphFunction(
            name = :RELU, 
            func = (x -> x < 0 ? 0 : x), 
            arity = 1
        )
    )
end


function mutate(
    mutator::FunctionGraphMutator,
    rng::AbstractRNG, 
    gene_id_counter::Counter, 
    geno::FunctionGraphGenotype
) 
    mutations = sample(
        rng, 
        collect(keys(mutator.mutation_probabilities)), 
        Weights(collect(values(mutator.mutation_probabilities))), 
        mutator.n_mutations
    )
    for mutation in mutations
        #println("MUTATION TYPE: ", mutation)
        geno = mutation(rng, gene_id_counter, geno, mutator.function_map)
    end
    inject_noise!(rng, geno, std_dev = mutator.noise_std)
    return geno
end

end
