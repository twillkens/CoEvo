module SimpleFunctionGraphs

export SimpleFunctionGraphMutator, add_node!, remove_node!, mutate_node!, mutate_edge!
export identity, inject_noise!
export mutate, mutate!

import Base: identity
import ..Mutators: mutate, mutate!

using Base: @kwdef
using Random: rand, randn, AbstractRNG
using StatsBase: sample, Weights
using ...Counters: Counter, count!
using ...Genotypes.SimpleFunctionGraphs: SimpleFunctionGraphGenotype, SimpleFunctionGraphNode
using ...Genotypes.SimpleFunctionGraphs: SimpleFunctionGraphEdge, FUNCTION_MAP
using ...Abstract.States: State
using ...Abstract
using ...Genotypes.SimpleFunctionGraphs: GraphFunction, validate_genotype, inject_noise!
using ...Genotypes.SimpleFunctionGraphs: add_node!, remove_node!, mutate_node!, mutate_edge!

using Random: shuffle!


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
    recurrent_edge_probability::Float64 = 0.1
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
    validate_genotypes::Bool = false
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

function mutate!(
    mutator::SimpleFunctionGraphMutator, genotype::SimpleFunctionGraphGenotype, state::State
)
    n_mutations = get_n_mutations(
        state.rng, mutator.max_mutations, mutator.n_mutations_decay_rate
    )
    mutation_symbols = sample_mutation_symbols(state.rng, mutator, n_mutations)
    #println("mutations = $mutation_symbols")
    #println("hidden_node_ids = $(genotype.hidden_node_ids)")
    #println("rng_state = $(rng.state)")
    for mutation_symbol in mutation_symbols
        mutation_function! = MUTATION_MAP[mutation_symbol]
        mutation_function!(genotype, mutator, state)
        if mutator.validate_genotypes
            validate_genotype(genotype, mutation_symbol)
        end
    end
    inject_noise!(state.rng, genotype, std_dev = mutator.noise_std)
    #println("genotype = $genotype")
end

mutate(mutator::SimpleFunctionGraphMutator, genotype::SimpleFunctionGraphGenotype, state::State
) = mutate!(mutator, deepcopy(genotype), state)

end
