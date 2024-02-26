module Identity

export IdentitySelector

import ....Interfaces: select
using ....Abstract
using ...Selectors.Selections: BasicSelection
using Random

# Define the IdentitySelector struct
# Since IdentitySelector doesn't need any configuration, it doesn't have fields.
# However, we define it to conform to the interface and conventions.
struct IdentitySelector <: Selector end

# Extend the select function to include an additional method that
# matches the signature used in the UniformRandom module for state-based selection.
function select(::IdentitySelector, records::Vector{<:Record}, ::State)
    # Directly use the select function defined above, as the IdentitySelector
    # doesn't require different logic based on the presence of a State object.
    selections = [BasicSelection([record]) for record in records]
    return selections
end

end
