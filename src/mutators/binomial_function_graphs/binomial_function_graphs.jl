module BinomialFunctionGraphs

export mutate, mutate!
export BinomialFunctionGraphMutator, clone_node!, remove_node!, mutate_node!, mutate_edge!
export mutate_bias!, mutate_weight!

import ..Mutators: mutate, mutate!

using Base: @kwdef
using Random: rand, randn, AbstractRNG
using StatsBase: sample, Weights
using ...Counters: Counter, count!
using ...Genotypes.SimpleFunctionGraphs: SimpleFunctionGraphGenotype
using ...Genotypes.SimpleFunctionGraphs: FUNCTION_MAP
using ...Abstract.States: State
using ...Abstract
using ...Genotypes.SimpleFunctionGraphs: GraphFunction, validate_genotype, inject_noise!
using ...Genotypes.SimpleFunctionGraphs: clone_node!, remove_node!, mutate_node!, mutate_bias!
using ...Genotypes.SimpleFunctionGraphs: mutate_edge!, mutate_weight!, add_node!

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

Base.@kwdef struct BinomialFunctionGraphMutator <: Mutator
    n_minimum_hidden_nodes::Int = 1
    # Number of structural changes to perform per generation
    recurrent_edge_probability::Float64 = 0.1
    # Uniform probability of each type of structural change
    mutation_rates::Dict{String, Float64} = Dict(
        "CLONE_NODE" =>  0.01,
        "REMOVE_NODE" => 0.02,
        "MUTATE_NODE" => 0.05,
        "MUTATE_BIAS" => 0.10,
        "MUTATE_EDGE" => 0.05,
        "MUTATE_WEIGHT" => 0.10,
    )
    mutation_map = Dict(
        "CLONE_NODE" => clone_node!,
        "REMOVE_NODE" => remove_node!,
        "MUTATE_NODE" => mutate_node!,
        "MUTATE_BIAS" => mutate_bias!,
        "MUTATE_EDGE" => mutate_edge!,
        "MUTATE_WEIGHT" => mutate_weight!,
    )
    bias_value_range::Tuple{Float32, Float32} = Float32.((-π, π))
    weight_value_range::Tuple{Float32, Float32} = Float32.((-π, π))
    function_set::Vector{Symbol} = LARGE
    validate_genotypes::Bool = false
end

function apply_mutations!(
    mutator::BinomialFunctionGraphMutator, 
    genotype::SimpleFunctionGraphGenotype, 
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
    mutator::BinomialFunctionGraphMutator, 
    genotype::SimpleFunctionGraphGenotype,
    function_string::String,
    state::State
)
    if function_string in ["CLONE_NODE", "REMOVE_NODE", "MUTATE_NODE"]
        n_elements = length(genotype.hidden_nodes)
    elseif function_string in ["MUTATE_EDGE"]
        n_elements = length(genotype.edges)
    else
        throw(ErrorException("Invalid function string: $function_string"))
    end
    mutation_rate = mutator.mutation_rates[function_string]
    n_samples = sample_binomial(state.rng, n_elements, mutation_rate)
    mutation_strings = [function_string for _ in 1:n_samples]
    return mutation_strings
end

function mutate_size!(
    mutator::BinomialFunctionGraphMutator, genotype::SimpleFunctionGraphGenotype, state::State
)
    size_mutations = [
        sample_binomial_mutations(mutator, genotype, "CLONE_NODE", state) ;
        sample_binomial_mutations(mutator, genotype, "REMOVE_NODE", state) ;
    ]
    shuffle!(state.rng, size_mutations)
    #println("size_mutations = $size_mutations")
    apply_mutations!(mutator, genotype, size_mutations, state)
end

function mutate_sites!(
    mutator::BinomialFunctionGraphMutator, genotype::SimpleFunctionGraphGenotype, state::State
)
    site_mutations = [
        sample_binomial_mutations(mutator, genotype, "MUTATE_NODE", state) ;
        sample_binomial_mutations(mutator, genotype, "MUTATE_EDGE", state) ;
    ]
    shuffle!(state.rng, site_mutations)
    #println("site_mutations = $site_mutations")
    apply_mutations!(mutator, genotype, site_mutations, state)
end

function mutate_values!(
    mutator::BinomialFunctionGraphMutator, genotype::SimpleFunctionGraphGenotype, state::State
)
    for node in [genotype.hidden_nodes ; genotype.output_nodes]
        if rand(state.rng) < mutator.mutation_rates["MUTATE_BIAS"]
            mutate_bias!(node, mutator, state)
        end
    end
    for edge in genotype.edges
        if rand(state.rng) < mutator.mutation_rates["MUTATE_WEIGHT"]
            mutate_weight!(edge, mutator, state)
        end
    end
end

function mutate!(
    mutator::BinomialFunctionGraphMutator, genotype::SimpleFunctionGraphGenotype, state::State
)
    mutate_size!(mutator, genotype, state)
    mutate_sites!(mutator, genotype, state)
    mutate_values!(mutator, genotype, state)
end

mutate(mutator::BinomialFunctionGraphMutator, genotype::SimpleFunctionGraphGenotype, state::State
) = mutate!(mutator, deepcopy(genotype), state)

end
