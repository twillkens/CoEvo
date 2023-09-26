"""
    Jobs

The `Jobs` module focuses on handling and configuring interaction jobs. It incorporates
various utilities and domain-specific functionalities, as well as interaction types to
facilitate job processing in the ecosystem.

# Structure
- `InteractionJob`: Represents the core structure of an interaction job.
- `InteractionJobConfiguration`: Provides configuration options for `InteractionJob`.
- Utility functions: Found in "utilities/utilities.jl".
- Domain-specific functionalities: Resourced from "deps/domains/domains.jl".
- Interaction types: Defined within "types/interaction.jl".
"""
module Jobs

# Exports
export InteractionJob, InteractionJobConfiguration

# Inclusion of external scripts
include("utilities/utilities.jl")
include("deps/domains/domains.jl")
include("types/interaction.jl")

end
