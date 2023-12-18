module FunctionGraphs

export FunctionGraphMutator, add_function, remove_function, swap_function
export redirect_connection, identity, inject_noise!, ConnectionRedirectionSpecification
export get_all_substitutions, get_substitutions_for_node, get_genotype_after_swapping_functions
export get_functions_with_arity, create_input_connections, select_function
export mutate

import Base: identity
import ..Mutators: mutate

using Base: @kwdef
using Random: rand, randn, AbstractRNG
using StatsBase: sample, Weights
using ...Counters: Counter, count!
using ...Genotypes.FunctionGraphs: FunctionGraphGenotype, FunctionGraphNode
using ...Genotypes.FunctionGraphs: FunctionGraphConnection, FUNCTION_MAP
using ..Mutators: Mutator

@kwdef struct ConnectionRedirectionSpecification
    node_id::Int
    input_connection_index::Int
    new_input_node_id::Int
end

# Define equality
function Base.:(==)(
    a::ConnectionRedirectionSpecification, b::ConnectionRedirectionSpecification
)
    return a.node_id == b.node_id &&
           a.input_connection_index == b.input_connection_index &&
           a.new_input_node_id == b.new_input_node_id
end

# Define hash
function Base.hash(a::ConnectionRedirectionSpecification, h::UInt)
    return hash(a.node_id, hash(a.input_connection_index, hash(a.new_input_node_id, h)))
end

function select_function(rng::AbstractRNG, function_probabilities::Dict{Symbol, Float64})
    func_symbol = sample(
        rng,
        collect(keys(function_probabilities)), 
        Weights(collect(values(function_probabilities)))
    )
    func = FUNCTION_MAP[func_symbol]
    return func
end

function create_input_connections(
    rng::AbstractRNG, 
    potential_input_node_ids::Vector{Int}, 
    arity::Int
)
    input_connections = [
        FunctionGraphConnection(
            input_node_id = rand(rng, potential_input_node_ids),
            weight = 0.0,  
            is_recurrent = true 
        ) 
        for _ in 1:arity
    ]
    return input_connections
end

function add_function(
    rng::AbstractRNG, 
    gene_id_counter::Counter, 
    graph::FunctionGraphGenotype, 
    function_probabilities::Dict{Symbol, Float64}
)
    graph = deepcopy(graph)
    new_id = count!(gene_id_counter)
    # TODO: Make excluding bias nodes an option
    func = select_function(rng, function_probabilities)
    potential_input_node_ids = [
        graph.input_node_ids; graph.bias_node_ids; graph.hidden_node_ids
        #graph.input_node_ids; graph.hidden_node_ids
    ]
    input_connections = create_input_connections(
        rng, potential_input_node_ids, func.arity
    )
    new_node = FunctionGraphNode(
        id = new_id, func = func.name, input_connections = input_connections
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
        nodes = new_nodes,
        n_nodes_per_output = genotype.n_nodes_per_output
    )

    return genotype
end

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
            immediate_redirects = filter(
                x -> x.input_node_id != node_to_delete_id, 
                genotype.nodes[node_to_delete_id].input_connections
            )
            if isempty(immediate_redirects)
                valid_nodes = setdiff(
                    union(
                        genotype.input_node_ids, 
                        genotype.bias_node_ids, 
                        genotype.hidden_node_ids
                    ), 
                    [node_to_delete_id]
                )
                if isempty(valid_nodes)
                    throw(ErrorException("No valid nodes to redirect to for output node"))
                end
                new_input_node_id = rand(rng, valid_nodes)
            else
                new_input_node_id = rand(
                    rng, [x.input_node_id for x in immediate_redirects]
                )
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
    ::Dict{Symbol, Float64}
)
    if length(genotype.hidden_node_ids) == 0
        return deepcopy(genotype)
    end
    node_to_delete_id = rand(rng, genotype.hidden_node_ids)
    substitutions = get_all_substitutions(genotype, node_to_delete_id, rng)
    
    return remove_function(genotype, node_to_delete_id, substitutions)
end

function get_functions_with_arity(
    arity::Int, eligible_functions::Vector{Symbol}
)
    functions_with_same_arity = [
        FUNCTION_MAP[func_symbol] for func_symbol in eligible_functions 
            if FUNCTION_MAP[func_symbol].arity == arity
    ]
    return functions_with_same_arity
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
        id = node_id, 
        func = new_function, 
        input_connections = new_nodes[node_id].input_connections
    )
    genotype = FunctionGraphGenotype(
        input_node_ids = genotype.input_node_ids, 
        bias_node_ids = genotype.bias_node_ids, 
        hidden_node_ids = genotype.hidden_node_ids, 
        output_node_ids = genotype.output_node_ids, 
        nodes = new_nodes,
        n_nodes_per_output = genotype.n_nodes_per_output
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
    genotype::FunctionGraphGenotype,
    all_mutator_functions::Vector{Symbol}
)
    if length(genotype.hidden_node_ids) == 0
        return deepcopy(genotype)
    end
    target_node_id = rand(rng, genotype.hidden_node_ids)
    arity = FUNCTION_MAP[genotype.nodes[target_node_id].func].arity
    eligible_functions = get_functions_with_arity(arity, all_mutator_functions)
    new_function = rand(rng, eligible_functions)
    genotype = get_genotype_after_swapping_functions(genotype, target_node_id, new_function.name)
    return genotype
end

function swap_function(
    rng::AbstractRNG,
    ::Counter,
    genotype::FunctionGraphGenotype,
    function_probabilities::Dict{Symbol, Float64}
)
    genotype = swap_function(
        rng, genotype, collect(keys(function_probabilities))
    )
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
    ::Dict{Symbol, Float64}
)
    # Choose a random node from hidden and output nodes
    redirection_source_candidate_ids = [genotype.hidden_node_ids ; genotype.output_node_ids]
    node_id = rand(rng, redirection_source_candidate_ids)
    # Choose a random connection index to redirect
    input_connection_index = rand(
        rng, 1:length(genotype.nodes[node_id].input_connections)
    )
    # Choose a random new input node from input, bias, and hidden nodes
    redirection_target_candidate_ids = [
        genotype.input_node_ids ; genotype.bias_node_ids ; genotype.hidden_node_ids
        #genotype.input_node_ids ; genotype.hidden_node_ids
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
    ::AbstractRNG, 
    ::Counter, 
    genotype::FunctionGraphGenotype, 
    ::Dict{Symbol, Float64}
)
    return deepcopy(genotype)
end

function inject_noise!(genotype::FunctionGraphGenotype, noise_map::Dict{Int, Vector{Float32}})
    for (node_id, node) in genotype.nodes
        if haskey(noise_map, node_id)
            noise_values = noise_map[node_id]
            for (i, conn) in enumerate(node.input_connections)
                if i <= length(noise_values)
                    conn.weight += noise_values[i]
                    if isinf(conn.weight) || isnan(conn.weight)
                        println("genotype = $genotype")
                        println("noise_map = $noise_map")
                        throw(ErrorException("Invalid weight"))
                    end
                end
            end
        end
    end
end

function inject_noise!(
    rng::AbstractRNG, 
    genotype::FunctionGraphGenotype; 
    std_dev::Float32 = 0.1f0
)
    noise_map = Dict{Int, Vector{Float32}}()
    
    # Generating the noise_map
    for (node_id, node) in genotype.nodes
        if !isempty(node.input_connections)  # Only for nodes with connections
            noise_values = randn(
                rng, length(node.input_connections)
            ) .* std_dev  # Assuming normal distribution for noise
            noise_map[node_id] = noise_values
        end
    end
    
    # Using deterministic function to inject noise
    inject_noise!(genotype, noise_map)
end

MUTATION_MAP = Dict(
    :add_function => add_function,
    :remove_function => remove_function,
    :swap_function => swap_function,
    :redirect_connection => redirect_connection,
    :identity => identity
)

Base.@kwdef struct FunctionGraphMutator <: Mutator
    # Number of structural changes to perform per generation
    n_mutations::Int = 1
    validate_genotypes::Bool = false
    # Uniform probability of each type of structural change
    exclude_bias_from_mutation::Bool = false
    mutation_probabilities::Dict{Symbol, Float64} = Dict(
        :identity => 0.5,
        :add_function => 0.1,
        :remove_function => 0.15,
        :swap_function => 0.125,
        :redirect_connection => 0.125
    )
    noise_std::Float32 = 0.1
    function_probabilities::Dict{Symbol, Float64} = Dict(
        :IDENTITY => 1 / 13,
        :ADD => 1 / 13,
        :SUBTRACT => 1 / 13,
        :MULTIPLY => 1 / 13,
        :DIVIDE => 1 / 13,
        :MAXIMUM => 1 / 13,
        :MINIMUM => 1 / 13,
        :SINE => 1 / 13,
        :COSINE => 1 / 13,
        :ARCTANGENT => 1 / 13,
        :SIGMOID => 1 / 13,
        :TANH => 1 / 13,
        :RELU => 1 / 13
    )
end

function validate_genotype(
    genotype::FunctionGraphGenotype,
    n_input_nodes::Int,
    n_bias_nodes::Int,
    n_hidden_nodes::Int,
    n_output_nodes::Int
)
    # 1. Ensure Unique IDs
    function_map = FUNCTION_MAP
    ids = Set{Int}()
    for (id, node) in genotype.nodes
        @assert id == node.id "ID mismatch in node dictionary and node struct"
        @assert !(id in ids) "Duplicate node ID: $id"
        push!(ids, id)
    end
    
    # 2. Output Node Constraints & 3. Input Constraints
    for (id, node) in genotype.nodes
        is_output_node = id in genotype.output_node_ids
        for conn in node.input_connections
            if is_output_node
                @assert !conn.is_recurrent "Output nodes must have nonrecurrent inputs"
            else
                @assert conn.is_recurrent "Non-output nodes must have recurrent inputs"
            end
        end
    end
    
    # 4. Avoid Output as Input
    for (id, node) in genotype.nodes
        if id in genotype.output_node_ids
            continue  # Skip the output nodes
        end
        for conn in node.input_connections
            @assert !(conn.input_node_id in genotype.output_node_ids) "Output node serving as input"
        end
    end
    
    # 5. Ensure Proper Arity
    for (_, node) in genotype.nodes
        expected_arity = function_map[node.func].arity
        @assert length(node.input_connections) == expected_arity "Incorrect arity for function $(node.func)"
    end
        # 6. Validate input connection ids
    for (_, node) in genotype.nodes
        for conn in node.input_connections
            @assert haskey(genotype.nodes, conn.input_node_id) "Input node id $(conn.input_node_id) does not exist in the network"
        end
    end
        # 7. Check number and IDs of :INPUT labeled nodes against genotype.input_node_ids
    input_node_ids_check = Set([id for (id, node) in genotype.nodes if node.func == :INPUT])
    @assert Set(genotype.input_node_ids) == input_node_ids_check "Mismatched set of IDs for :INPUT nodes"
    @assert length(genotype.input_node_ids) == n_input_nodes "Mismatched number of :INPUT nodes"

    # 8. Check number and IDs of :BIAS labeled nodes against genotype.bias_node_ids
    bias_node_ids_check = Set([id for (id, node) in genotype.nodes if node.func == :BIAS])
    @assert Set(genotype.bias_node_ids) == bias_node_ids_check "Mismatched set of IDs for :BIAS nodes"
    @assert length(genotype.bias_node_ids) == n_bias_nodes "Mismatched number of :BIAS nodes"

    # 10. Check number and IDs of hidden nodes against genotype.hidden_node_ids
    hidden_node_ids_check = Set([id for (id, node) in genotype.nodes if node.func ∉ [:INPUT, :BIAS, :OUTPUT]])
    @assert Set(genotype.hidden_node_ids) == hidden_node_ids_check "Mismatched set of IDs for hidden nodes"
    @assert length(genotype.hidden_node_ids) in [n_hidden_nodes, n_hidden_nodes + 1, n_hidden_nodes - 1 ] "Mismatched number of hidden nodes"

    # 9. Check number and IDs of :OUTPUT labeled nodes against genotype.output_node_ids
    output_node_ids_check = Set([id for (id, node) in genotype.nodes if node.func == :OUTPUT])
    @assert Set(genotype.output_node_ids) == output_node_ids_check "Mismatched set of IDs for :OUTPUT nodes"
    @assert length(genotype.output_node_ids) == n_output_nodes "Mismatched number of :OUTPUT nodes"
end

function mutate(
    mutator::FunctionGraphMutator,
    rng::AbstractRNG, 
    gene_id_counter::Counter, 
    genotype::FunctionGraphGenotype
) 
    mutations = sample(
        rng, 
        collect(keys(mutator.mutation_probabilities)), 
        Weights(collect(values(mutator.mutation_probabilities))), 
        mutator.n_mutations
    )
    #println("mutator = $mutator")
    #println("mutations = $mutations")
    n_input_nodes = length(genotype.input_node_ids)
    n_bias_nodes = length(genotype.bias_node_ids)
    n_hidden_nodes = length(genotype.hidden_node_ids)
    n_output_nodes = length(genotype.output_node_ids)
    for mutation in mutations
        mutation_function = MUTATION_MAP[mutation]
        genotype = mutation_function(
            rng, gene_id_counter, genotype, mutator.function_probabilities
        )
    end
    inject_noise!(rng, genotype, std_dev = mutator.noise_std)
    if mutator.validate_genotypes
        validate_genotype(genotype, n_input_nodes, n_bias_nodes, n_hidden_nodes, n_output_nodes)
    end
    return genotype
end

end
