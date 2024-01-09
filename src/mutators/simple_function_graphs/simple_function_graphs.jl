module SimpleFunctionGraphs

export SimpleFunctionGraphMutator, add_node!, remove_node!, mutate_node!, mutate_edge!
export identity, inject_noise!, EdgeSubstitution
export get_all_substitutions, create_edges, select_function, mutate

import Base: identity
import ..Mutators: mutate

using Base: @kwdef
using Random: rand, randn, AbstractRNG
using StatsBase: sample, Weights
using ...Counters: Counter, count!
using ...Genotypes.SimpleFunctionGraphs: SimpleFunctionGraphGenotype, SimpleFunctionGraphNode
using ...Genotypes.SimpleFunctionGraphs: SimpleFunctionGraphEdge, FUNCTION_MAP
using ...Abstract.States: State
using ..Mutators: Mutator
using ...Genotypes.SimpleFunctionGraphs: GraphFunction

using Random: shuffle!


function add_node!(genotype::SimpleFunctionGraphGenotype, node::SimpleFunctionGraphNode)
    push!(genotype.nodes, node)
end

function select_function(rng::AbstractRNG, function_set::Vector{Symbol})
    func_symbol = rand(rng, function_set)
    func = FUNCTION_MAP[func_symbol]
    return func
end

function create_edges(rng::AbstractRNG, potential_targets::Vector{Int}, arity::Int)
    edges = [
        SimpleFunctionGraphEdge(
            target = rand(rng, potential_targets),
            weight = 0.0,  
            is_recurrent = true 
        ) 
        for _ in 1:arity
    ]
    return edges
end

function add_node!(
    rng::AbstractRNG, 
    gene_id_counter::Counter, 
    genotype::SimpleFunctionGraphGenotype, 
    function_set::Vector{Symbol}
)
    new_id = count!(gene_id_counter)
    # TODO: Make excluding bias nodes an option
    func = select_function(rng, function_set)
    potential_targets = [genotype.input_ids; genotype.bias_ids; genotype.hidden_ids]
    edges = create_edges(rng, potential_targets, func.arity)
    new_node = SimpleFunctionGraphNode(id = new_id, func = func.name, edges = edges)
    add_node!(genotype, new_node)
end

@kwdef struct EdgeSubstitution
    node_id::Int
    edge_index::Int
    target::Int
end

function perform_substitution!(
    genotype::SimpleFunctionGraphGenotype, substitution::EdgeSubstitution
)
    node = genotype[substitution.node_id]
    connection = node.edges[substitution.edge_index]
    connection.target = substitution.target
end

# Define equality
function Base.:(==)(
    a::EdgeSubstitution, b::EdgeSubstitution
)
    return a.node_id == b.node_id &&
           a.edge_index == b.edge_index &&
           a.target == b.target
end

# Define hash
function Base.hash(a::EdgeSubstitution, h::UInt)
    return hash(a.node_id, hash(a.edge_index, hash(a.target, h)))
end

function remove_node!(
    genotype::SimpleFunctionGraphGenotype, 
    node_to_delete_id::Int, 
    substitutions::Vector{EdgeSubstitution}
)
    illegal_to_remove = [
        genotype.input_ids ; genotype.bias_ids ; genotype.output_ids
    ]
    if node_to_delete_id in illegal_to_remove
        throw(ErrorException("Cannot remove input, bias, or output node"))
    end
    filter!(node -> node.id != node_to_delete_id, genotype.nodes)
    [perform_substitution!(genotype, substitution) for substitution in substitutions]
end

function get_all_substitutions(
    genotype::SimpleFunctionGraphGenotype, node_to_delete_id::Int, rng::AbstractRNG
)
    nodes = [node for node in genotype.nodes if node.id != node_to_delete_id]
    non_output_ids = [
        genotype.input_ids ; genotype.bias_ids ; genotype.hidden_ids
    ]
    valid_targets = [id for id in non_output_ids if id != node_to_delete_id]

    substitutions = EdgeSubstitution[]
    for node in nodes
        for (index, edge) in enumerate(node.edges)
            if edge.target == node_to_delete_id
                substitution = EdgeSubstitution(
                    node_id = node.id,
                    edge_index = index,
                    target = rand(rng, valid_targets)
                )
                push!(substitutions, substitution)
            end
        end
    end
    
    return substitutions
end

function remove_node!(rng::AbstractRNG, genotype::SimpleFunctionGraphGenotype,)
    if length(genotype.hidden_ids) == 0
        return 
    end
    node_to_delete_id = rand(rng, genotype.hidden_ids)
    substitutions = get_all_substitutions(genotype, node_to_delete_id, rng)
    remove_node!(genotype, node_to_delete_id, substitutions)
end

remove_node!(
    rng::AbstractRNG, ::Counter, genotype::SimpleFunctionGraphGenotype, ::Vector{Symbol}
) = remove_node!(rng, genotype)

function create_edges(rng::AbstractRNG, genotype::SimpleFunctionGraphGenotype, n_edges::Int)
    potential_targets = [genotype.input_ids ; genotype.bias_ids ; genotype.hidden_ids]
    edges = [
        SimpleFunctionGraphEdge(
            target = rand(rng, potential_targets),
            weight = 0.0,  
            is_recurrent = true 
        ) 
        for _ in 1:n_edges
    ]
    return edges
end

function sample_edges(rng::AbstractRNG, node::SimpleFunctionGraphNode, n_edges::Int)
    edges = sample(rng, node.edges, n_edges, replace = false)
    return edges
end

function mutate_node!(
    node::SimpleFunctionGraphNode, 
    new_function::Symbol, 
    new_edges::Vector{SimpleFunctionGraphEdge}
)
    node.func = new_function
    node.edges = new_edges
end

function mutate_node!(
    rng::AbstractRNG, genotype::SimpleFunctionGraphGenotype, function_set::Vector{Symbol}
)
    if length(genotype.hidden_ids) == 0
        return
    end
    node = rand(rng, genotype.hidden_nodes)
    old_function = FUNCTION_MAP[node.func]
    new_function = FUNCTION_MAP[rand(rng, function_set)]
    if old_function.arity < new_function.arity
        # Add edges
        n_new_edges = new_function.arity - old_function.arity
        new_edges = create_edges(rng, genotype, n_new_edges)
        all_edges = [node.edges ; new_edges] 
    else
        # Remove edges
        n_edges_to_remove = old_function.arity - new_function.arity
        edges_to_remove = sample_edges(rng, node, n_edges_to_remove)
        all_edges = filter(edge -> !(edge in edges_to_remove), node.edges)
    end
    shuffle!(rng, all_edges)
    mutate_node!(node, new_function.name, all_edges)
end

mutate_node!(
    rng::AbstractRNG, ::Counter, genotype::SimpleFunctionGraphGenotype, function_set::Vector{Symbol}
) = mutate_node!(rng, genotype, function_set)

function mutate_edge!(genotype::SimpleFunctionGraphGenotype, substitution::EdgeSubstitution)
    node = genotype[substitution.node_id]
    edge = node.edges[substitution.edge_index]
    edge.target = substitution.target
end

function mutate_edge!(rng::AbstractRNG, genotype::SimpleFunctionGraphGenotype,)
    valid_nodes = [genotype.hidden_nodes ; genotype.output_nodes]
    node = rand(rng, valid_nodes)
    edge_index = rand(rng, 1:length(node.edges))
    valid_targets = [genotype.input_ids ; genotype.bias_ids ; genotype.hidden_ids]
    target = rand(rng, valid_targets)
    substitution = EdgeSubstitution(
        node_id = node.id,
        edge_index = edge_index,
        target = target
    )
    mutate_edge!(genotype, substitution)
end

mutate_edge!(
    rng::AbstractRNG, ::Counter, genotype::SimpleFunctionGraphGenotype, ::Vector{Symbol}
) = mutate_edge!(rng, genotype)

function inject_noise!(node::SimpleFunctionGraphNode, noise_values::Vector{Float32})
    for (edge, noise_value) in zip(node.edges, noise_values)
        edge.weight += noise_value
        if isinf(edge.weight) || isnan(edge.weight)
            println("node = $node")
            println("noise_values = $noise_values")
            throw(ErrorException("Invalid weight"))
        end
    end
end

function inject_noise!(
    genotype::SimpleFunctionGraphGenotype, noise_map::Dict{Int, Vector{Float32}}
)
    for node in genotype.nodes
        if haskey(noise_map, node.id)
            noise_values = noise_map[node.id]
            if length(node.edges) != length(noise_values)
                println("genotype = $genotype")
                println("noise_map = $noise_map")
                throw(ErrorException("Mismatched number of noise values"))
            end
            inject_noise!(node, noise_values)
        end
    end
end

function inject_noise!(
    rng::AbstractRNG, genotype::SimpleFunctionGraphGenotype; std_dev::Float32 = 0.1f0
)
    noise_map = Dict{Int, Vector{Float32}}()
    
    # Generating the noise_map
    for node in genotype.nodes
        if !isempty(node.edges)  # Only for nodes with edges
            noise_values = randn(rng, length(node.edges)) .* std_dev  # Assuming normal distribution for noise
            noise_map[node.id] = noise_values
        end
    end
    
    # Using deterministic function to inject noise
    inject_noise!(genotype, noise_map)
end

MUTATION_MAP = Dict(
    :add_node! => add_node!,
    :remove_node! => remove_node!,
    :mutate_node! => mutate_node!,
    :mutate_edge! => mutate_edge!,
)

Base.@kwdef struct SimpleFunctionGraphMutator <: Mutator
    # Number of structural changes to perform per generation
    max_mutations::Int = 10
    n_mutations_decay_rate::Float64 = 0.5
    validate_genotypes::Bool = false
    # Uniform probability of each type of structural change
    mutation_weights::Dict{Symbol, Float64} = Dict(
        :add_node! => 1.0,
        :remove_node! => 1.0,
        :mutate_node! => 1.0,
        :mutate_edge! => 1.0,
    )
    noise_std::Float32 = 0.1
    function_set::Vector{Symbol} = [
        :IDENTITY, :ADD, :MULTIPLY, :DIVIDE, :MAXIMUM, :MINIMUM, :SINE, :COSINE,
        :ARCTANGENT, :SIGMOID, :TANH, :RELU, :IF_LESS_THEN_ELSE
    ]
end

function validate_genotype(genotype::SimpleFunctionGraphGenotype,)
    # 1. Ensure Unique IDs
    ids = Set{Int}()
    for node in genotype.nodes
        id = node.id
        if id in ids
            throw(ErrorException("Duplicate node ID"))
        end
        push!(ids, id)
    end
    
    # 2. Output Node Constraints 
    for node in genotype.nodes
        for edge in node.edges
            if edge.target in genotype.output_node_ids
                throw(ErrorException("Output node serving as input"))
            end
        end
    end
    
    # 3. Ensure Proper Arity
    for node in genotype.nodes
        expected_arity = FUNCTION_MAP[node.func].arity
        if length(node.edges) != expected_arity
            throw(ErrorException("Incorrect arity for function $(node.func)"))
        end
    end
    # 4. Validate input connection ids
    for node in genotype.nodes
        for edge in node.edges
            if !(edge.target in genotype.node_ids)
                throw(ErrorException("Invalid input node ID"))
            end
        end
    end
end

function get_n_mutations(rng::AbstractRNG, max_mutations::Int, decay_rate::Float64)
    # Create probabilities for each possible number of mutations
    probabilities = exp.(-decay_rate * collect(0:max_mutations-1))
    # Normalize the probabilities so they sum to 1
    probabilities /= sum(probabilities)
    # Sample a number of mutations based on the probabilities
    n_mutations = sample(rng, Weights(probabilities))
    return n_mutations
end

function sample_mutation_symbol(rng::AbstractRNG, mutator::SimpleFunctionGraphMutator)
    mutation_symbol = sample(
        rng, 
        Weights(collect(values(mutator.mutation_weights))),
        keys(mutator.mutation_weights)
    )
    return mutation_symbol
end

function sample_mutation_symbols(
    rng::AbstractRNG, mutator::SimpleFunctionGraphMutator, n_mutations::Int
)
    mutation_symbols = collect(keys(mutator.mutation_weights))
    weights = Weights(collect(values(mutator.mutation_weights)))
    mutation_symbols = sample(rng, mutation_symbols, weights, n_mutations)
    return mutation_symbols
end

function mutate(
    mutator::SimpleFunctionGraphMutator,
    rng::AbstractRNG, 
    gene_id_counter::Counter, 
    genotype::SimpleFunctionGraphGenotype
) 
    genotype = deepcopy(genotype)
    n_mutations = get_n_mutations(rng, mutator.max_mutations, mutator.n_mutations_decay_rate)
    mutation_symbols = sample_mutation_symbols(rng, mutator, n_mutations)
    #println("mutator = $mutator")
    #println("mutations = $mutations")
    #println("hidden_node_ids = $(genotype.hidden_node_ids)")
    #println("rng_state = $(rng.state)")
    for mutation_symbol in mutation_symbols
        mutation_function! = MUTATION_MAP[mutation_symbol]
        mutation_function!(rng, gene_id_counter, genotype, mutator.function_set)
    end
    inject_noise!(rng, genotype, std_dev = mutator.noise_std)
    if mutator.validate_genotypes
        validate_genotype(genotype,)
    end
    return genotype
end

mutate(
    mutator::SimpleFunctionGraphMutator, genotype::SimpleFunctionGraphGenotype, state::State
) = mutate(mutator, state.rng, state.gene_id_counter, genotype)

end
