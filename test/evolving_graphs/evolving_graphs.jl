using Test
using Base: @kwdef
using CoEvo
using Random: AbstractRNG

import Base: ==
# Define a map for function symbols to actual functions

struct GraphFunction
    name::Symbol
    func::Function
    arity::Int
end

function(graph_function::GraphFunction)(args...)
    output = graph_function.func(args...)
    return output
end

# function ==(gf1::GraphFunction, gf2::GraphFunction)
#     return gf1.name == gf2.name
# end
# 
# function ==(gf1::Symbol, gf2::GraphFunction)
#     return gf1 == gf2.name
# end
# 
# function ==(gf1::GraphFunction, gf2::Symbol)
#     return gf1 == gf2.name
# end

const FUNCTION_MAP = Dict(
    :INPUT => GraphFunction(:INPUT, identity, 1),
    :OUTPUT => GraphFunction(:OUTPUT, identity, 1),

    :IDENTITY => GraphFunction(:IDENTITY, identity, 1),

    :ADD => GraphFunction(:ADD, (+), 2),
    :SUBTRACT => GraphFunction(:SUBTRACT, (-), 2),
    :MULTIPLY => GraphFunction(:MULTIPLY, (*), 2),
    :DIVIDE => GraphFunction(:DIVIDE, ((x, y) -> y == 0 ? 1.0 : x / y), 2),

    :MAXIMUM => GraphFunction(:MAXIMUM, max, 2),
    :MINIMUM => GraphFunction(:MINIMUM, min, 2),

    :SIN => GraphFunction(:SIN, sin, 1),
    :COSINE => GraphFunction(:COSINE, cos, 1),
    :SIGMOID => GraphFunction(:SIGMOID, (x -> 1 / (1 + exp(-x))), 2),
    :TANH => GraphFunction(:TANH, tanh, 1),
    :RELU => GraphFunction(:RELU, (x -> x < 0 ? 0 : x), 1),

    :AND => GraphFunction(:AND, ((x, y) -> Bool(x) && Bool(y)), 2),
    :OR => GraphFunction(:OR, ((x, y) -> Bool(x) || Bool(y)), 2),
    :NAND => GraphFunction(:NAND, ((x, y) -> !(Bool(x) && Bool(y))), 2),
    :XOR => GraphFunction(:XOR, ((x, y) -> Bool(x) ⊻ Bool(y)), 2),
)

@kwdef struct FunctionGraphConnection
    input_id::Int
    weight::Float64
    is_recurrent::Bool
end

@kwdef struct FunctionGraphNode
    id::Int
    func::Symbol
    input_ids::Vector{Tuple{Int, Bool}}
end


@kwdef struct FunctionGraphGenotype <: Genotype
    input_node_ids::Vector{Int}
    output_node_ids::Vector{Int}
    hidden_node_ids::Vector{Int}
    nodes::Dict{Int, FunctionGraphNode}
    # Add more fields if needed
end

@kwdef struct FunctionGraphGenotypeCreator <: GenotypeCreator
    n_input_nodes::Int
    n_output_nodes::Int
end

using CoEvo.Ecosystems.Utilities.Counters: Counter, next!

function create_genotypes(
    genotype_creator::FunctionGraphGenotypeCreator, 
    rng::AbstractRNG,
    gene_id_counter::Counter,
    n_pop::Int
)
    genotypes = FunctionGraphGenotype[]
    for _ in 1:n_pop
        input_node_ids = next!(gene_id_counter, genotype_creator.n_input_nodes)
        output_node_ids = next!(gene_id_counter, genotype_creator.n_output_nodes)
        input_nodes = Dict(
            id => FunctionGraphNode(
                id = id, 
                func = :INPUT, 
                input_ids = Tuple{Int, Bool}[]
            ) for id in input_node_ids
        )
        output_nodes = Dict(
            id => FunctionGraphNode(
                id = id, 
                func = :OUTPUT, 
                input_ids = [(rand(rng, input_node_ids), false)]
            ) for id in output_node_ids
        )
        nodes = merge(input_nodes, output_nodes)
        genotype = FunctionGraphGenotype(input_node_ids, output_node_ids, Int[], nodes)
        push!(genotypes, genotype)
    end

    return genotypes
end


using StatsBase: sample

function add_node(
    rng::AbstractRNG, 
    gene_id_counter::Counter, 
    graph::FunctionGraphGenotype, 
    function_map::Dict{Symbol, GraphFunction} = FUNCTION_MAP
)
    graph = deepcopy(graph)
    new_id = next!(gene_id_counter)
    func_symbol = sample(rng, collect(keys(FUNCTION_MAP)))
    available_inputs = [graph.input_node_ids; graph.hidden_node_ids ; new_id]
    arity = function_map[func_symbol].arity
    input_ids = [(rand(rng, available_inputs), true) for _ in 1:arity]
    
    new_node = FunctionGraphNode(
        id = new_id,
        func = func_symbol,
        input_ids = input_ids
    )
    
    graph.nodes[new_id] = new_node
    
    return graph
end

gene_id_counter = Counter()
using StableRNGs: StableRNG
rng = StableRNG(1234)

genotype_creator = FunctionGraphGenotypeCreator(1, 1)
genotype = create_genotypes(genotype_creator, rng, gene_id_counter, 1)[1]
mutant = add_node(rng, gene_id_counter, genotype)
@test length(keys(mutant.nodes)) == 3


function get_nodes_with_redirected_links(
    graph::FunctionGraphGenotype, 
    todelete::Int
)
    # Create a new nodes dictionary to avoid changing the original during iteration
    new_nodes = deepcopy(graph.nodes)

    # Identify the nodes which link to the deleted node
    for (id, node) in graph.nodes
        if id == todelete
            continue # skip the node to be deleted
        end

        # Check if node points to the deleted node
        new_input_ids = map(node.input_ids) do (input_id, _)
            if input_id == todelete
                # Choose a replacement link from deleted node's inputs, or self-link if not possible
                possible_redirects = filter(x -> x[1] != todelete, graph.nodes[todelete].input_ids)
                if isempty(possible_redirects)
                    new_link = (id, true)  # self-link if no other options
                else
                    new_link = rand(possible_redirects)  # randomly select an alternative link
                end
            else
                new_link = (input_id, true)
            end
            new_link
        end
        
        # Update links for the node
        new_nodes[id] = FunctionGraphNode(id, node.func, new_input_ids)
    end
    
    return new_nodes
end

function remove_node(genotype::FunctionGraphGenotype, todelete::Int)
    # Ensure the node to delete is not an input or output node
    if (todelete in genotype.input_node_ids) || (todelete in genotype.output_node_ids)
        throw(ErrorException("Cannot remove input or output node"))
    end
    
    # Filter the links
    new_nodes = get_nodes_with_redirected_links(genotype, todelete)

    # Remove the node
    delete!(new_nodes, todelete)
    hidden_node_ids = filter(x -> x != todelete, genotype.hidden_node_ids)

    genotype = FunctionGraphGenotype(
        genotype.input_node_ids, 
        genotype.output_node_ids, 
        hidden_node_ids,
        new_nodes
    )

    return genotype
end

function remove_node(
    rng::AbstractRNG, 
    ::Counter, 
    genotype::FunctionGraphGenotype, 
    ::Dict{Symbol, GraphFunction} = FUNCTION_MAP
)
    # Ensure the node to delete is not an input or output node
    to_delete = rand(rng, graph.hidden_node_ids)
    remove_node(genotype, to_delete)
end


geno = FunctionGraphGenotype(
    input_node_ids = [0],
    output_node_ids = [6],
    hidden_node_ids = [1, 2, 3, 4, 5],
    nodes = Dict(
        6 => FunctionGraphNode(6, :OUTPUT, [(5, false)]),
        5 => FunctionGraphNode(5, :ADD, [(3, false), (4, false)]),
        4 => FunctionGraphNode(4, :MULTIPLY, [(2, true), (3, true)]),
        3 => FunctionGraphNode(3, :MAXIMUM, [(5, true), (1, false)]),
        2 => FunctionGraphNode(2, :IDENTITY, [(1, true)]),
        1 => FunctionGraphNode(1, :IDENTITY, [(0, false)]),
        0 => FunctionGraphNode(0, :INPUT, []),
    )
)

mutant = remove_node(geno, 2)
println(mutant.nodes)

@test length(keys(mutant.nodes)) == 6
@test mutant.nodes[4].input_ids == [(1, true), (3, true)]

mutant = remove_node(mutant, 1)
@test length(keys(mutant.nodes)) == 5
@test mutant.nodes[4].input_ids == [(0, true), (3, true)]
@test mutant.nodes[3].input_ids == [(5, true), (0, true)]

mutant = remove_node(mutant, 3)
@test length(keys(mutant.nodes)) == 4

mutant = remove_node(mutant, 4)
@test length(keys(mutant.nodes)) == 3

mutant = remove_node(mutant, 5)
@test length(keys(mutant.nodes)) == 2

@test_throws ErrorException remove_node(mutant, 0)
@test_throws ErrorException remove_node(mutant, 6)


function swap_function(

)

end

function swap_function(
    rng::AbstractRNG, 
    ::Counter, 
    genotype::FunctionGraphGenotype, 
    ::Dict{Symbol, GraphFunction} = FUNCTION_MAP
)
    node_id = rand(rng, collect(keys(graph.nodes)))
    curr_arity = FUNCTION_MAP[graph.nodes[node_id].func].arity
    
    # Select a new function maintaining the same arity.
    new_func = sample(rng, [f for f in values(FUNCTION_MAP) if f.arity == curr_arity])
    graph.nodes[node_id].func = new_func.name
    
    return graph

end


return




#function create_genotypes()

@kwdef mutable struct FunctionGraphStatefulNode
    id::Int
    func::Symbol
    current_value::Union{Float64, Nothing} = nothing
    previous_value::Float64 = 0.0
    input_nodes::Vector{Pair{FunctionGraphStatefulNode, Bool}}
    seeking_output::Bool = false
end

function FunctionGraphStatefulNode(stateless_node::FunctionGraphNode)
    stateful_node = FunctionGraphStatefulNode(
        id = stateless_node.id,
        func = stateless_node.func,
        current_value = nothing,
        previous_value = 0.0,
        input_nodes = Pair{FunctionGraphStatefulNode, Bool}[],
        seeking_output = false
    )
    return stateful_node
end

@kwdef mutable struct FunctionGraphPhenotype <: Phenotype
    input_node_ids::Vector{Int}
    output_node_ids::Vector{Int}
    nodes::Dict{Int, FunctionGraphStatefulNode}
end

function print_phenotype_state(phenotype::FunctionGraphPhenotype)
    # Extracting nodes from phenotype and sorting them by id.
    sorted_nodes = sort(collect(values(phenotype.nodes)), by = node -> node.id)
    # Printing the nodes' state
    println("IDENTITY\tPrevious Value\tCurrent Value")
    for node in sorted_nodes
        println("$(node.id)\t$(node.previous_value)\t$(node.current_value)")
    end
end

function create_phenotype(::PhenotypeCreator, geno::FunctionGraphGenotype)::FunctionGraphPhenotype
    # Initialize node values with zeros for simplicity
    all_nodes = Dict(id => FunctionGraphStatefulNode(node) for (id, node) in geno.nodes)
    for (id, node) in all_nodes
        node.input_nodes = [
            all_nodes[input_id] => is_recurrent
            for (input_id, is_recurrent) in geno.nodes[id].input_ids
        ]
    end

    phenotype = FunctionGraphPhenotype(
        geno.input_node_ids, 
        geno.output_node_ids, 
        all_nodes
    )

    return phenotype
end

function get_output!(node::FunctionGraphStatefulNode, is_recurrent_edge::Bool)
    if node.func == :INPUT
        return node.current_value
    elseif node.seeking_output
        return is_recurrent_edge ? node.previous_value : node.current_value
    end
    node.seeking_output = true
    if node.current_value === nothing
        input_values = [
            get_output!(input_node, is_recurrent_edge) 
            for (input_node, is_recurrent_edge) in node.input_nodes
        ]
        node_function = FUNCTION_MAP[node.func]
        output_value = node_function(input_values...)
        node.current_value = output_value
    end
    output_value = is_recurrent_edge ? node.previous_value : node.current_value
    node.seeking_output = false
    return output_value
end

# Additional Helper Functions

function act!(phenotype::FunctionGraphPhenotype, input_values::Vector{Float64})
    # Update previous_values before the new round of computation

    for node in values(phenotype.nodes)
        node.previous_value = node.current_value === nothing ? 
            node.previous_value : node.current_value
        node.current_value = nothing
    end

    for (index, input_value) in enumerate(input_values)
        input_node = phenotype.nodes[phenotype.input_node_ids[index]]
        input_node.current_value = input_value
    end

    output_values = Float64[]

    for output_node_id in phenotype.output_node_ids
        output_node = phenotype.nodes[output_node_id]
        output_value = get_output!(output_node, false)
        push!(output_values, output_value)
    end
    
    return output_values
end

function reset!(phenotype::FunctionGraphPhenotype)
    for node in phenotype.nodes
        node.current_value = nothing
        node.previous_value = 0.0
    end
end

# Example FunctionGraphGenotype
geno = FunctionGraphGenotype(
    input_node_ids = [0],
    output_node_ids = [6],
    hidden_node_ids = [1, 2, 3, 4, 5],
    nodes = Dict(
        6 => FunctionGraphNode(6, :OUTPUT, [(5, false)]),
        5 => FunctionGraphNode(5, :ADD, [(3, false), (4, false)]),
        4 => FunctionGraphNode(4, :MULTIPLY, [(2, true), (3, true)]),
        3 => FunctionGraphNode(3, :MAXIMUM, [(5, true), (1, false)]),
        2 => FunctionGraphNode(2, :IDENTITY, [(1, true)]),
        1 => FunctionGraphNode(1, :IDENTITY, [(0, false)]),
        0 => FunctionGraphNode(0, :INPUT, []),
    )
)

# FunctionGraphPhenotype Creation and Evaluation
phenotype_creator = DefaultPhenotypeCreator()
phenotype = create_phenotype(phenotype_creator, geno)
input_values = [1.0]
output = act!(phenotype, input_values)
@test output == [1.0]
output = act!(phenotype, input_values)
@test output == [1.0]
output = act!(phenotype, input_values)
@test output == [2.0]
output = act!(phenotype, input_values)
@test output == [3.0]
output = act!(phenotype, input_values)
@test output == [5.0]
output = act!(phenotype, input_values)
@test output == [8.0]
output = act!(phenotype, input_values)
@test output == [13.0]

geno = FunctionGraphGenotype(
    input_node_ids = [1, 2],
    output_node_ids = [6],
    hidden_node_ids = [3, 4, 5],
    nodes = Dict(
        6 => FunctionGraphNode(6, :OUTPUT, [(5, false)]),
        5 => FunctionGraphNode(5, :AND, [(3, false), (4, false)]),
        4 => FunctionGraphNode(4, :OR, [(1, false), (2, false)]),
        3 => FunctionGraphNode(3, :NAND, [(1, false), (2, false)]),
        2 => FunctionGraphNode(2, :INPUT, []),
        1 => FunctionGraphNode(1, :INPUT, []),
    )
)

phenotype_creator = DefaultPhenotypeCreator()
phenotype = create_phenotype(phenotype_creator, geno)
input_values = [1.0, 1.0]
output = act!(phenotype, input_values)
@test output == [0.0]
input_values = [0.0, 1.0]
output = act!(phenotype, input_values)
@test output == [1.0]
input_values = [1.0, 0.0]
output = act!(phenotype, input_values)
@test output == [1.0]
input_values = [0.0, 0.0]
output = act!(phenotype, input_values)
@test output == [0.0]

geno = FunctionGraphGenotype(
    input_node_ids = [1, 2, 3],
    output_node_ids = [10, 11],
    hidden_node_ids = [4, 5, 6, 7, 8, 9],
    nodes = Dict(
        11 => FunctionGraphNode(11, :OUTPUT, [(8, false)]),
        10 => FunctionGraphNode(10, :OUTPUT, [(9, false)]),
        9 => FunctionGraphNode(9, :OR, [(5, false), (6, false)]),
        8 => FunctionGraphNode(8, :XOR, [(3, false), (4, false)]),
        7 => FunctionGraphNode(7, :AND, [(3, false), (4, false)]),
        6 => FunctionGraphNode(6, :AND, [(1, false), (2, false)]),
        5 => FunctionGraphNode(5, :AND, [(3, false), (4, false)]),
        4 => FunctionGraphNode(4, :XOR, [(1, false), (2, false)]),
        3 => FunctionGraphNode(3, :INPUT, []),
        2 => FunctionGraphNode(2, :INPUT, []),
        1 => FunctionGraphNode(1, :INPUT, []),
    )
)
phenotype_creator = DefaultPhenotypeCreator()
phenotype = create_phenotype(phenotype_creator, geno)

input_values = [
    [0.0, 0.0, 0.0],
    [0.0, 0.0, 1.0],
    [0.0, 1.0, 0.0],
    [0.0, 1.0, 1.0],
    [1.0, 0.0, 0.0],
    [1.0, 0.0, 1.0],
    [1.0, 1.0, 0.0],
    [1.0, 1.0, 1.0],
]

expected_values = [
    [0.0, 0.0],
    [0.0, 1.0],
    [0.0, 1.0],
    [1.0, 0.0],
    [0.0, 1.0],
    [1.0, 0.0],
    [1.0, 0.0],
    [1.0, 1.0],
]
@test all([
    act!(phenotype, input_values[i]) == expected_values[i] 
    for i in eachindex(input_values)]
)

geno = FunctionGraphGenotype(
    input_node_ids = [1, 2, 3, 4],
    output_node_ids = [9],
    hidden_node_ids = [5, 6, 7, 8],
    nodes = Dict(
        9 => FunctionGraphNode(9, :OUTPUT, [(8, false)]),
        8 => FunctionGraphNode(8, :MULTIPLY, [(1, false), (7, false)]),
        7 => FunctionGraphNode(7, :DIVIDE, [(5, false), (6, false)]),
        6 => FunctionGraphNode(6, :MULTIPLY, [(4, false), (4, false)]),
        5 => FunctionGraphNode(5, :MULTIPLY, [(2, false), (3, false)]),
        4 => FunctionGraphNode(4, :INPUT, []),
        3 => FunctionGraphNode(3, :INPUT, []),
        2 => FunctionGraphNode(2, :INPUT, []),
        1 => FunctionGraphNode(1, :INPUT, []),
    )
)
newtons_law_of_gravitation = (g, m1, m2, r) -> (g * m1 * m2) / (r^2)

phenotype_creator = DefaultPhenotypeCreator()
phenotype = create_phenotype(phenotype_creator, geno)

input_values = [6.674e-11, 5.972e24, 7.348e22, 3.844e8]

output = act!(phenotype, input_values)
expected = [newtons_law_of_gravitation(input_values...)]
@test output[1] ≈ expected[1]