using CoEvo
using CoEvo.Abstract
using CoEvo.Interfaces
using CoEvo.Concrete.Genotypes.FiniteStateMachines
using CoEvo.Concrete.Counters.Basic
using Random
"""
    create_random_genotype(
        genotype_creator::FiniteStateMachineGenotypeCreator,
        rng::AbstractRNG,
        gene_id_counter::Counter,
        n_states::Int
    )

Generates a new `FiniteStateMachineGenotype` instance with a specified number of states and random transitions.

# Arguments
- `genotype_creator::FiniteStateMachineGenotypeCreator`: Instance to facilitate genotype creation.
- `rng::AbstractRNG`: RNG to assist random state label generation.
- `gene_id_counter::Counter`: Counter to keep track of gene IDs.
- `n_states::Int`: Number of states in the genotype.

# Returns
- `FiniteStateMachineGenotype{Int}`: A genotype with `n_states` states and random transitions.
"""
function create_random_fsm_genotype(
    ::FiniteStateMachineGenotypeCreator,
    n_states::Int,
    gene_id_counter::Counter = BasicCounter(),
    rng::AbstractRNG = Random.GLOBAL_RNG,
)
    # Generate state IDs
    state_ids = [step!(gene_id_counter) for _ in 1:n_states]

    # Randomly assign labels to states
    ones = Set{Int}()
    zeros = Set{Int}()
    for state_id in state_ids
        if rand(rng, Bool)
            push!(ones, state_id)
        else
            push!(zeros, state_id)
        end
    end

    # Create random transitions
    links = Dict{Tuple{Int, Bool}, Int}()
    for state_id in state_ids
        for bit in [true, false]
            next_state = rand(rng, state_ids)
            links[(state_id, bit)] = next_state
        end
    end

    # Select a random start state
    start_state = rand(rng, state_ids)

    # Create the FiniteStateMachineGenotype
    genotype = FiniteStateMachineGenotype(start_state, ones, zeros, links)
    return genotype
end
