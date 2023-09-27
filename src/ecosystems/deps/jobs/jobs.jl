"""
    Jobs

The `Jobs` module focuses on handling and configuring interaction jobs. It incorporates
various utilities and domain-specific functionalities, as well as interaction types to
facilitate job processing in the ecosystem.

# Structure
- `BasicJob`: Represents the core structure of an interaction job.
- `InteractionJobConfiguration`: Provides configuration options for `BasicJob`.
- Utility functions: Found in "utilities/utilities.jl".
- Domain-specific functionalities: Resourced from "deps/domains/domains.jl".
- Interaction types: Defined within "types/interaction.jl".
"""
module Jobs

# Exports
export BasicJob, BasicJobCreator

# Inclusion of external scripts
include("utilities/utilities.jl")
include("deps/interactions.jl")

include("types/basic.jl")

end
