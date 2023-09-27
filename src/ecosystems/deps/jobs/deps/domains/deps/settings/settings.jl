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
module Settings

# Exported Structures and Functions
export NumbersGame

# Dependencies
include("types/numbers_game/numbers_game.jl")

# Imports from NumbersGame submodule
using .NumbersGame: NumbersGame

end
