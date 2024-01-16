module FunctionGraphs

export mutate, mutate!
export FunctionGraphMutator, clone_node!, remove_node!, mutate_node!, mutate_edge!
export mutate_bias!, mutate_weight!

import ....Interfaces: mutate, mutate!
using ....Abstract
using ....Interfaces

using Base: @kwdef
using Random: rand, randn, AbstractRNG
using StatsBase: sample, Weights
using ...Genotypes.FunctionGraphs: FunctionGraphGenotype
using ...Genotypes.FunctionGraphs: FUNCTION_MAP
using ...Genotypes.FunctionGraphs: GraphFunction, validate_genotype, inject_noise!
using ...Genotypes.FunctionGraphs: clone_node!, remove_node!, mutate_node!, mutate_bias!
using ...Genotypes.FunctionGraphs: mutate_edge!, mutate_weight!, add_node!

using Random: shuffle!
using Distributions: Binomial, Uniform

const LARGE = [
    :IDENTITY,
    :ADD,
    :SUBTRACT,
    :MULTIPLY,
    :DIVIDE,
    :SINE,
    :COSINE,
    :SIGMOID,
    :TANH,
    :RELU,
    :MAXIMUM,
    :MINIMUM,
    :IF_LESS_THEN_ELSE,
    :MODULO,
    :NATURAL_LOG,
    :EXP,
]


Base.@kwdef struct FunctionGraphMutator <: Mutator
    n_minimum_hidden_nodes::Int = 0
    # Number of structural changes to perform per generation
    recurrent_edge_probability::Float64 = 0.1
    # Uniform probability of each type of structural change
    mutation_map = Dict(
        "ADD_NODE" => add_node!,
        "REMOVE_NODE" => remove_node!,
        "MUTATE_NODE" => mutate_node!,
        "MUTATE_EDGE" => mutate_edge!,
    )
    binomial_rates::Dict{String, Float64} = Dict(
        "ADD_NODE" =>  0.005,
        "REMOVE_NODE" => 0.01,
        "MUTATE_NODE" => 0.02,
        "MUTATE_EDGE" => 0.02,
    )
    max_mutations::Int = 5
    n_mutations_decay_rate::Float64 = 0.5
    exponential_weights::Dict{String, Float64} = Dict(
        "ADD_NODE" => 1.0,
        "REMOVE_NODE" => 2.0,
        "MUTATE_NODE" => 20.0,
        "MUTATE_EDGE" => 20.0,
    )
    probability_mutate_bias::Float64 = 0.02
    bias_value_range::Tuple{Float32, Float32} = Float32.((-π, π))
    probability_mutate_weight::Float64 = 0.02
    weight_value_range::Tuple{Float32, Float32} = Float32.((-π, π))
    noise_std::Float32 = 0.01
    probability_inject_noise_bias::Float64 = 1.0
    probability_inject_noise_weight::Float64 = 1.0
    function_set::Vector{Symbol} = LARGE
    validate_genotypes::Bool = false
end

function apply_mutations!(
    mutator::FunctionGraphMutator, 
    genotype::FunctionGraphGenotype, 
    mutations::Vector{String},
    state::State
)
    for mutation in mutations
        mutation_function! = mutator.mutation_map[mutation]
        mutation_function!(genotype, mutator, state)
        if length(genotype.hidden_nodes) < mutator.n_minimum_hidden_nodes
            n_new_nodes = mutator.n_minimum_hidden_nodes - length(genotype.hidden_nodes)
            for _ in 1:n_new_nodes
                add_node!(genotype, mutator, state)
            end
        end
        if mutator.validate_genotypes
            validate_genotype(genotype, mutation)
        end
    end
end

sample_binomial(rng::AbstractRNG, n::Int, rate::Float64) = rand(rng, Binomial(n, rate))

function sample_binomial_mutations(
    mutator::FunctionGraphMutator, 
    genotype::FunctionGraphGenotype,
    function_string::String,
    state::State
)
    if function_string in ["ADD_NODE", "REMOVE_NODE", "MUTATE_NODE"]
        n_elements = length(genotype.hidden_nodes)
    elseif function_string in ["MUTATE_EDGE"]
        n_elements = length(genotype.edges)
    else
        throw(ErrorException("Invalid function string: $function_string"))
    end
    mutation_rate = mutator.binomial_rates[function_string]
    n_samples = sample_binomial(state.rng, n_elements, mutation_rate)
    mutation_strings = [function_string for _ in 1:n_samples]
    return mutation_strings
end

function get_n_mutations(mutator::FunctionGraphMutator, state::State)
    # Create probabilities for each possible number of mutations
    probabilities = exp.(-mutator.n_mutations_decay_rate * collect(0:mutator.max_mutations - 1))
    # Normalize the probabilities so they sum to 1
    probabilities /= sum(probabilities)
    # Sample a number of mutations based on the probabilities
    n_mutations = sample(state.rng, Weights(probabilities))
    return n_mutations
end

function sample_exponential_mutations(mutator::FunctionGraphMutator, state::State)
    n_mutations = get_n_mutations(mutator, state)
    mutation_symbols = collect(keys(mutator.exponential_weights))
    weights = Weights(collect(values(mutator.exponential_weights)))
    mutation_symbols = sample(state.rng, mutation_symbols, weights, n_mutations)
    return mutation_symbols
end

function mutate_structure!(
    mutator::FunctionGraphMutator, genotype::FunctionGraphGenotype, state::State
)
    exponential_mutations = sample_exponential_mutations(mutator, state)
    binomial_mutations = [
        sample_binomial_mutations(mutator, genotype, "ADD_NODE", state) ;
        sample_binomial_mutations(mutator, genotype, "REMOVE_NODE", state) ;
        sample_binomial_mutations(mutator, genotype, "MUTATE_NODE", state) ;
        sample_binomial_mutations(mutator, genotype, "MUTATE_EDGE", state) ;
    ]
    mutations = [exponential_mutations ; binomial_mutations]
    #println("n_mutations = ", length(mutations))
    shuffle!(state.rng, mutations)
    #println("site_mutations = $site_mutations")
    apply_mutations!(mutator, genotype, mutations, state)
end

function mutate_values!(
    mutator::FunctionGraphMutator, genotype::FunctionGraphGenotype, state::State
)
    for node in [genotype.hidden_nodes ; genotype.output_nodes]
        if rand(state.rng) < mutator.probability_mutate_bias
            mutate_bias!(node, mutator, state)
        end
        if rand(state.rng) < mutator.probability_inject_noise_bias
            inject_noise!(node, mutator, state)
        end
    end
    for edge in genotype.edges
        if rand(state.rng) < mutator.probability_mutate_weight
            mutate_weight!(edge, mutator, state)
        end
        if rand(state.rng) < mutator.probability_inject_noise_weight
            inject_noise!(edge, mutator, state)
        end
    end
end

function mutate!(mutator::FunctionGraphMutator, genotype::FunctionGraphGenotype, state::State)
    mutate_structure!(mutator, genotype, state)
    mutate_values!(mutator, genotype, state)
end

mutate(mutator::FunctionGraphMutator, genotype::FunctionGraphGenotype, state::State) = 
    mutate!(mutator, deepcopy(genotype), state)

end
