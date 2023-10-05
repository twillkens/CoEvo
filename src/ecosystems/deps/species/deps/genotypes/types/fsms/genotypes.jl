module Genotypes

export FiniteStateMachineGenotype, FiniteStateMachineGenotypeCreator

using Random: AbstractRNG, rand

using .....Ecosystems.Utilities.Counters: Counter, next!
using ...Genotypes.Abstract: Genotype, GenotypeCreator

import ...Genotypes.Interfaces: create_genotypes
import Base: ==
import Base: hash
import Base: length

struct FiniteStateMachineGenotype{T} <: Genotype
    start::T
    ones::Set{T}
    zeros::Set{T}
    links::Dict{Tuple{T, Bool}, T}
end

function Base.show(io::IO, fsm::FiniteStateMachineGenotype)
    print(io, "FiniteStateMachineGenotype:\n")
    print(io, "  Start: ", fsm.start, "\n")
    print(io, "  Ones: ", fsm.ones, "\n")
    print(io, "  Zeros: ", fsm.zeros, "\n")
    print(io, "  Links:\n")
    for (k, v) in fsm.links
        print(io, "    ", k, " => ", v, "\n")
    end
end

struct FiniteStateMachineGenotypeCreator <: GenotypeCreator end

Base.length(geno::FiniteStateMachineGenotype) = length(geno.ones) + length(geno.zeros)

function create_genotype(
    ::FiniteStateMachineGenotypeCreator,
    id::Int,
    start_state_label::Bool
)
    ones, zeros = start_state_label ?
        (Set([id]), Set{Int}()) : (Set{Int}(), Set([id]))
    links = Dict(((id, true) => id, (id, false) => id))
    genotype = FiniteStateMachineGenotype(id, ones, zeros, links)
end

function create_genotype(
    genotype_creator::FiniteStateMachineGenotypeCreator,
    rng::AbstractRNG,
    gene_id_counter::Counter,
)
    id = next!(gene_id_counter)
    start_state_label = rand(rng, Bool)
    genotype = create_genotype(genotype_creator, id, start_state_label)
    return genotype
end

# Creates a new FSMIndiv with a single state
function create_genotypes(
    genotype_creator::FiniteStateMachineGenotypeCreator,
    rng::AbstractRNG, 
    gene_id_counter::Counter,
    n_pop::Int
)
    genotypes = [create_genotype(genotype_creator, rng, gene_id_counter) for _ in 1:n_pop]
    return genotypes
end

function Base.:(==)(fsm1::FiniteStateMachineGenotype, fsm2::FiniteStateMachineGenotype)
    return is_isomorphic(fsm1, fsm2)
end

function is_isomorphic(fsm1::FiniteStateMachineGenotype, fsm2::FiniteStateMachineGenotype)
    # Check if both FSMs have the same number of states
    if length(fsm1.ones) != length(fsm2.ones) || length(fsm1.zeros) != length(fsm2.zeros)
        return false
    end

    # Recursive DFS to compare states
    function dfs(state1, state2, visited)
        if haskey(visited, state1)
            return visited[state1] == state2
        end

        visited[state1] = state2

        # Check outgoing links
        for bit in [true, false]
            next1 = get(fsm1.links, (state1, bit), nothing)
            next2 = get(fsm2.links, (state2, bit), nothing)

            if (next1 === nothing && next2 !== nothing) || (next1 !== nothing && next2 === nothing)
                return false
            elseif next1 !== nothing && next2 !== nothing && !dfs(next1, next2, visited)
                return false
            end
        end

        # Check if both states are either in ones or in zeros
        in_ones1 = state1 in fsm1.ones
        in_ones2 = state2 in fsm2.ones
        in_zeros1 = state1 in fsm1.zeros
        in_zeros2 = state2 in fsm2.zeros

        return (in_ones1 && in_ones2 && !in_zeros1 && !in_zeros2) ||
               (!in_ones1 && !in_ones2 && in_zeros1 && in_zeros2)
    end

    return dfs(fsm1.start, fsm2.start, Dict())
end


function fsm_hash(fsm::FiniteStateMachineGenotype{T}, h::UInt) where T
    result = []

    # Helper function to add state details to result
    function add_state_details(state)
        for bit in [true, false]
            next_state = get(fsm.links, (state, bit), nothing)
            if next_state !== nothing
                push!(result, (
                    bit, 
                    state == fsm.start,
                    state in fsm.ones, 
                    state in fsm.zeros, 
                    next_state in fsm.ones, 
                    next_state in fsm.zeros)
                )
            end
        end
    end

    # Iterate over all states and add their details
    for state in keys(fsm.links)
        add_state_details(state)
    end

    # Sort transitions for consistent order
    sort!(result)

    return hash(result, h)
end


function Base.hash(x::FiniteStateMachineGenotype{T}, h::UInt=zero(UInt)) where T
    return fsm_hash(x, h)
end

end