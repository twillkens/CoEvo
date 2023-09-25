"""
    Utilities

The `Utilities` module aggregates essential utility types and functionalities that support various components 
of the coevolutionary system. These utilities provide mechanisms for criteria-based decision-making, 
statistical analysis, counting and tracking, and performance metrics assessment.

# Structure
This module is organized into specific submodules or included files, each targeting a specific utility aspect:

1. **Criteria**: Offers types and methods to make decisions based on certain conditions or criteria.
2. **Statistics**: Encompasses types related to statistical computations and analyses.
3. **Counters**: Provides types to track, count, and log specific events or occurrences.
4. **Metrics**: Introduces types to measure and evaluate various performance metrics across the coevolutionary process.

# Files
- `types/criteria.jl`: Contains types and functionalities related to criteria-based decisions.
- `types/statistics.jl`: Hosts types essential for statistical computations.
- `types/counters.jl`: Contains counter-related types to keep track of specific events.
- `types/metrics.jl`: Encompasses metric evaluation types for performance assessment.

# Usage
The utilities can be accessed by importing the specific type or function from the `Utilities` module.
"""

module Utilities

include("types/criteria.jl")
include("types/statistics.jl")
include("types/counters.jl")
include("types/metrics.jl")

end
