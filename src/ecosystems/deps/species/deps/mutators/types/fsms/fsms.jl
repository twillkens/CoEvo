module FiniteStateMachineMutators

export FiniteStateMachineMutator
export add_state, remove_state, change_link, change_label

using StatsBase: sample, Weights
using Random: AbstractRNG, rand

using ....Genotypes.FiniteStateMachines: FiniteStateMachineGenotype
using ...Mutators.Abstract: Mutator
using .....Ecosystems.Utilities.Counters: Counter, next!


function add_state(
    fsm::FiniteStateMachineGenotype{T}, 
    new_state::T, 
    label::Bool, 
    true_destination::T, 
    false_destination::T
) where T
    ones, zeros = label ? 
        union(fsm.ones, Set([new_state]), fsm.zeros) : 
        fsm.ones, union(fsm.zeros, Set([new_state]))
    new_links = Dict(
        (new_state, true) => true_destination, 
        (new_state, false) => false_destination
    )
    links = merge(fsm.links, new_links)
    genotype = FiniteStateMachineGenotype(fsm.start, ones, zeros, links)
    return genotype
end

function filter_links(fsm::FiniteStateMachineGenotype{T}, todelete::T) where T
    filtered_links = Dict{Tuple{T, Bool}, T}()
    for ((origin, bool), dest) in fsm.links
        if dest == todelete && origin != todelete
            new_destination = fsm.links[(todelete, bool)]
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

function filter_states(fsm::FiniteStateMachineGenotype{T}, to_delete::T) where T
    ones = to_delete in fsm.ones ? filter(state -> state != to_delete, fsm.ones) : fsm.ones
    zeros = to_delete in fsm.zeros ? filter(state -> state != to_delete, fsm.zeros) : fsm.zeros
    return ones, zeros
end

function remove_state(
    fsm::FiniteStateMachineGenotype{T}, 
    to_delete::T, 
    new_start::Union{T, Nothing} = nothing
) where T
    if to_delete == fsm.start
        if new_start === nothing
            throw(ErrorException("Cannot remove start state without specifying new start"))
        end
        start = new_start
    else
        start = fsm.start
    end
    ones, zeros = filter_states(fsm, to_delete)
    links = filter_links(fsm, to_delete)
    genotype = FiniteStateMachineGenotype(start, ones, zeros, links)
    return genotype
end

function change_label(fsm::FiniteStateMachineGenotype{T}, state::T) where T
    state_singleton = Set([state])
    ones, zeros = state ∈ fsm.ones ?
        (setdiff(fsm.ones, state_singleton), union(fsm.zeros, state_singleton)) :
        (union(fsm.ones, state_singleton), setdiff(fsm.zeros, state_singleton))
    genotype = FiniteStateMachineGenotype(fsm.start, ones, zeros, fsm.links)
    return genotype
end


function change_link(
    fsm::FiniteStateMachineGenotype{T}, state::T, new_destination::T, bit::Bool
) where T
    links = merge(fsm.links, Dict((state, bit) => new_destination))
    genotype = FiniteStateMachineGenotype(fsm.start, fsm.ones, fsm.zeros, links)
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
    mutation_functions = collect(keys(mutator.mutation_probabilities))
    mutation_probabilities = Weights(collect(values(mutator.mutation_probabilities)))
    mutation_functions = sample(
        rng, mutation_functions, mutation_probabilities, mutator.n_changes
    )
    for mutation_function in mutation_functions
        genotype = mutation_function(rng, gene_id_counter, genotype)
    end
    return genotype
end

function get_random_state(
    rng::AbstractRNG, fsm::FiniteStateMachineGenotype{T};
    include::Set{T} = Set{T}(), 
    exclude::Set{T} = Set{T}()
) where T
    nodes = union(fsm.ones, fsm.zeros, include)
    nodes = setdiff(nodes, exclude)
    random_state = rand(rng, nodes)
    return random_state
end

# add state

function new_state!(gene_id_counter::Counter, ::FiniteStateMachineGenotype{String})
    state = string(next!(gene_id_counter))
    return state
end


function new_state!(gene_id_counter::Counter, ::FiniteStateMachineGenotype{Int})
    state = next!(gene_id_counter)
    return state
end

function add_state(rng::AbstractRNG, gene_id_counter::Counter, fsm::FiniteStateMachineGenotype)
    label = rand(rng, Bool)
    new_state = new_state!(gene_id_counter, fsm)
    true_destination = get_random_state(rng, fsm; include = Set([new_state]))
    false_destination = get_random_state(rng, fsm, include = Set([new_state]))
    genotype = add_state(fsm, new_state, label, true_destination, false_destination)
    return genotype
end

function remove_state(rng::AbstractRNG, ::Counter, fsm::FiniteStateMachineGenotype)
    if length(fsm) == 1 return fsm end
    to_delete = get_random_state(rng, fsm)
    new_start = to_delete == fsm.start ? 
        get_random_state(rng, fsm; exclude = Set([to_delete])) : 
        nothing
    remove_state(fsm, to_delete, new_start)
end


function change_link(rng::AbstractRNG, ::Counter, fsm::FiniteStateMachineGenotype)
    state = get_random_state(rng, fsm)
    new_destination = get_random_state(rng, fsm)
    bit = rand(rng, Bool)
    genotype = change_link(fsm, state, new_destination, bit)
    return genotype
end

function change_label(rng::AbstractRNG, ::Counter, fsm::FiniteStateMachineGenotype)
    state = get_random_state(rng, fsm)
    genotype = change_label(fsm, state)
    return genotype
end


end