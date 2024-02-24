module Identity

export IdentitySelector, identity_select

import ....Interfaces: select
using ....Abstract
using ...Selectors.Selections: BasicSelection
using Random

# Define the IdentitySelector struct
# Since IdentitySelector doesn't need any configuration, it doesn't have fields.
# However, we define it to conform to the interface and conventions.
struct IdentitySelector <: Selector end

# Define the identity_select function.
# This function is a direct implementation of the selection logic for IdentitySelector.
# It simply returns the indices of the passed records without modification.
function identity_select(::AbstractRNG, n_records::Int)
    # For an identity selection, we simply return all indices as the selection.
    return 1:n_records
end

# Override the select function for IdentitySelector
# This function conforms to the pattern used in UniformRandom, taking similar parameters.
function select(
    ::IdentitySelector,
    records::Vector{<:Record},
    rng::AbstractRNG = Random.GLOBAL_RNG
)
    n_records = length(records)
    winner_indices = identity_select(rng, n_records)
    selection_set = [records[i] for i in winner_indices]
    selection = BasicSelection(selection_set)
    return selection
end

# Extend the select function to include an additional method that
# matches the signature used in the UniformRandom module for state-based selection.
function select(selector::IdentitySelector, records::Vector{<:Record}, state::State)
    # Directly use the select function defined above, as the IdentitySelector
    # doesn't require different logic based on the presence of a State object.
    selections = [BasicSelection([record]) for record in records]
    return selections
end

end
