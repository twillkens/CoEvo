module Clone

using ......Ecosystems.Utilities.Counters: Counter, next!

using Random: AbstractRNG
using ...Abstract: Recombiner
using ....Species.Individuals: Individual

import ...Recombiners.Interfaces: recombine

"""
    CloneRecombiner

Represents a recombination strategy that creates offspring by directly copying the genotype 
of the parents without any genetic crossover or mutation.

# Usage
Create instances of this struct and use them with the recombination function to produce offspring.
"""
Base.@kwdef struct CloneRecombiner <: Recombiner end

"""
    (recombiner::CloneRecombiner)(random_number_generator::AbstractRNG, individual_id_counter::Counter, parents::Vector{I})

Creates offspring by directly copying the genotype of the parents.

# Arguments
- `random_number_generator::AbstractRNG`: A random number generator (unused in this recombiner but maintained for a consistent interface).
- `individual_id_counter::Counter`: A counter object used to assign unique IDs to the newly created individuals.
- `parents::Vector{I}`: Vector of parent individuals.

# Returns
- `Vector{Individual}`: A list of cloned offspring individuals.
"""
function recombine(
    ::CloneRecombiner,
    ::AbstractRNG, 
    individual_id_counter::Counter, 
    parents::Vector{<:Individual}
) 
    children = [
        Individual(next!(individual_id_counter), parent.genotype, [parent.id]) for parent in parents
    ]
    return children
end

end