"""
    Problems

The `Problems` module offers structures and functionality associated with 
various problems. Currently, it includes the `NumbersGameProblem` and 
its associated interaction function.

# Structures
- `NumbersGameProblem`: Represents the definition of the Numbers Game problem.

# Functions
- `interact`: Defines the interaction mechanics for the Numbers Game problem.

# Dependencies
- `NumbersGame`: Contains structures and functions specific to the Numbers Game problem.
"""
module Environments

export Abstract, Interfaces, Types

include("abstract/abstract.jl")
using .Abstract: Abstract
# Exported Structures and Functions

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

# Dependencies
include("types/types.jl")
using .Types: Types

end
