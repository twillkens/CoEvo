module FiniteStateMachines

export FiniteStateMachineMutator
export add_state, remove_state, change_link, change_label

import ....Interfaces: mutate, mutate!

using Random: AbstractRNG, rand
using StatsBase: sample, Weights
using ....Abstract
using ....Interfaces
using ...Genotypes.FiniteStateMachines: FiniteStateMachineGenotype

function add_state(
    genotype::FiniteStateMachineGenotype{T}, 
    new_state::T, 
    label::Bool, 
    true_destination::T, 
    false_destination::T
) where T
    ones, zeros = label ? 
        (union(genotype.ones, Set([new_state])), genotype.zeros) : 
        (genotype.ones, union(genotype.zeros, Set([new_state])))
    new_links = Dict(
        (new_state, true) => true_destination, 
        (new_state, false) => false_destination
    )
    links = merge(genotype.links, new_links)
    genotype = FiniteStateMachineGenotype(genotype.start, ones, zeros, links)
    return genotype
end

function filter_links(genotype::FiniteStateMachineGenotype{T}, todelete::T) where T
    filtered_links = Dict{Tuple{T, Bool}, T}()
    for ((origin, bool), dest) in genotype.links
        if dest == todelete && origin != todelete
            new_destination = genotype.links[(todelete, bool)]
            new_destination = new_destination == todelete ? origin : new_destination
            push!(filtered_links, (origin, bool) => new_destination)
        elseif origin == todelete
            continue
        else
            push!(filtered_links, (origin, bool) => dest)
        end
    end
    return filtered_links
end

function filter_states(genotype::FiniteStateMachineGenotype{T}, to_delete::T) where T
    ones = to_delete in genotype.ones ? 
        filter(state -> state != to_delete, genotype.ones) : genotype.ones
    zeros = to_delete in genotype.zeros ? 
        filter(state -> state != to_delete, genotype.zeros) : genotype.zeros
    return ones, zeros
end

function remove_state(
    genotype::FiniteStateMachineGenotype{T}, 
    to_delete::T, 
    new_start::Union{T, Nothing} = nothing
) where T
    if to_delete == genotype.start
        if new_start === nothing
            throw(ErrorException("Cannot remove start state without specifying new start"))
        end
        start = new_start
    else
        start = genotype.start
    end
    ones, zeros = filter_states(genotype, to_delete)
    links = filter_links(genotype, to_delete)
    genotype = FiniteStateMachineGenotype(start, ones, zeros, links)
    return genotype
end

function change_label(genotype::FiniteStateMachineGenotype{T}, state::T) where T
    state_singleton = Set([state])
    ones, zeros = state ∈ genotype.ones ?
        (setdiff(genotype.ones, state_singleton), union(genotype.zeros, state_singleton)) :
        (union(genotype.ones, state_singleton), setdiff(genotype.zeros, state_singleton))
    genotype = FiniteStateMachineGenotype(genotype.start, ones, zeros, genotype.links)
    return genotype
end

function change_link(
    genotype::FiniteStateMachineGenotype{T}, state::T, new_destination::T, bit::Bool
) where T
    links = merge(genotype.links, Dict((state, bit) => new_destination))
    genotype = FiniteStateMachineGenotype(genotype.start, genotype.ones, genotype.zeros, links)
    return genotype
end

Base.@kwdef struct FiniteStateMachineMutator <: Mutator
    n_changes::Int = 1
    mutation_probabilities::Dict{Function, Float64} = Dict(
        add_state => 0.25,
        remove_state => 0.25,
        change_link => 0.25,
        change_label => 0.25
    )
end

function mutate(
    mutator::FiniteStateMachineMutator,
    rng::AbstractRNG, 
    gene_id_counter::Counter, 
    genotype::FiniteStateMachineGenotype
) 
    #genotype_before = genotype
    mutation_functions = collect(keys(mutator.mutation_probabilities))
    mutation_probabilities = Weights(collect(values(mutator.mutation_probabilities)))
    lambda = 0.5 # Rate parameter for the exponential distribution
    change_weights = Weights([exp(-lambda * (i - 1)) for i in 1:mutator.n_changes])
    n_changes = sample(rng, 1:mutator.n_changes, change_weights)
    mutation_functions = sample(rng, mutation_functions, mutation_probabilities, n_changes)
    for mutation_function in mutation_functions
        genotype = mutation_function(rng, gene_id_counter, genotype)
    end
    if length(
        union(genotype.ones, genotype.zeros)) != length(genotype.ones) + length(genotype.zeros
    )
        throw(ErrorException("Duplicate states in genotype"))
    end
    return genotype
end

function mutate!(
    mutator::FiniteStateMachineMutator,
    genotype::FiniteStateMachineGenotype,
    state::State
)
    mutant = mutate(mutator, state.rng, state.gene_id_counter, genotype)
    genotype.start = mutant.start
    genotype.ones = mutant.ones
    genotype.zeros = mutant.zeros
    genotype.links = mutant.links
    return genotype
end

function new_state!(gene_id_counter::Counter, ::FiniteStateMachineGenotype{String})
    state = string(step!(gene_id_counter))
    return state
end

function new_state!(gene_id_counter::Counter, ::FiniteStateMachineGenotype{Int})
    state = step!(gene_id_counter)
    return state
end

function add_state(
    rng::AbstractRNG, 
    gene_id_counter::Counter, 
    genotype::FiniteStateMachineGenotype)
    label = rand(rng, Bool
)
    new_state = new_state!(gene_id_counter, genotype)
    available_destinations = union(genotype.ones, genotype.zeros, Set([new_state]))
    true_destination = rand(rng, available_destinations)
    false_destination = rand(rng, available_destinations)
    genotype = add_state(genotype, new_state, label, true_destination, false_destination)
    return genotype
end

function remove_state(
    rng::AbstractRNG, ::Counter, genotype::FiniteStateMachineGenotype
)
    fsm_size = length(genotype)
    if fsm_size < 2 return deepcopy(genotype) end
    to_delete = rand(rng, union(genotype.ones, genotype.zeros))
    all_nodes = union(genotype.ones, genotype.zeros)
    to_delete_set = Set([to_delete])
    all_nodes_after_delete = setdiff(all_nodes, to_delete_set)
    if to_delete == genotype.start
        new_start = rand(rng, all_nodes_after_delete)
        genotype = remove_state(genotype, to_delete, new_start)
        return genotype
    end
    new_start = to_delete == genotype.start ? 
        rand(
            rng, 
            setdiff(union(genotype.ones, genotype.zeros), Set([to_delete]))
        ) : 
        nothing
    genotype = remove_state(genotype, to_delete, new_start)
    return genotype
end

function change_link(
    rng::AbstractRNG, ::Counter, genotype::FiniteStateMachineGenotype
)
    state = rand(rng, union(genotype.ones, genotype.zeros))
    new_destination = rand(rng, union(genotype.ones, genotype.zeros))
    bit = rand(rng, Bool)
    genotype = change_link(genotype, state, new_destination, bit)
    return genotype
end

function change_label(
    rng::AbstractRNG, ::Counter, genotype::FiniteStateMachineGenotype
)
    state = rand(rng, union(genotype.ones, genotype.zeros))
    genotype = change_label(genotype, state)
    return genotype
end

end