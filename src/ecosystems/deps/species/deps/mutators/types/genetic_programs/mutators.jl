module Mutators

export GeneticProgramMutator

using Random: AbstractRNG
using StatsBase: sample, Weights

using ......Ecosystems.Utilities.Counters: Counter, next!
using .....Genotypes.GeneticPrograms: GeneticProgramGenotype
using .....Genotypes.GeneticPrograms.Methods: Manipulate
using .Manipulate: add_function, remove_function, swap_node, splice_function, inject_noise
using .....Genotypes.GeneticPrograms.Methods.Traverse: all_nodes 
using .....Genotypes.GeneticPrograms.Utilities: Utilities
using .Utilities: FuncAlias, Terminal, protected_sine, if_less_then_else
using ....Mutators.Abstract: Mutator

import ....Mutators.Interfaces: mutate

Base.@kwdef struct GeneticProgramMutator <: Mutator
    # Number of structural changes to perform per generation
    n_mutations::Int = 1
    # Uniform probability of each type of structural change
    mutation_probabilities::Dict{Function, Float64} = Dict(
        add_function => 1 / 4,
        remove_function => 1 / 4,
        splice_function => 1 / 4,
        swap_node => 1 / 4,
    )
    terminals::Dict{Terminal, Int} = Dict(
        :read => 1, 
        0.0 => 1, 
    )
    functions::Dict{FuncAlias, Int} = Dict([
        (protected_sine, 1), 
        (+, 2), 
        (-, 2), 
        (*, 2),
        (if_less_then_else, 4),
    ])
    noise_std::Float64 = 0.1
    string_arg_dict::Dict{String, Any} = Dict(
        "read" => :read, 
        "+" => +, 
        "-" => -, 
        "*" => *, 
        "sin" => protected_sine, 
        "iflt" => if_less_then_else)
end

include("methods.jl")

using .Methods: add_function, remove_function, swap_node, splice_function, inject_noise

function mutate(
    mutator::GeneticProgramMutator,
    rng::AbstractRNG, 
    gene_id_counter::Counter, 
    geno::GeneticProgramGenotype
) 
    mutations = sample(
        rng, 
        collect(keys(mutator.mutation_probabilities)), 
        Weights(collect(values(mutator.mutation_probabilities))), 
        mutator.n_mutations
    )
    for mutation in mutations
        geno = mutation(rng, gene_id_counter, mutation, geno)
    end
    if geno.root_id ∉ keys(all_nodes(geno))
        throw(ErrorException("Root node not in genotype"))
    end
    geno = inject_noise(rng, gene_id_counter, mutator, geno)
    if geno.root_id ∉ keys(all_nodes(geno))
        throw(ErrorException("Root node not in genotype after noise"))
    end
    return geno
end

end