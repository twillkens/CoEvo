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
module Domains

export NumbersGame, Abstract

module Abstract

export Domain, DomainCreator, create_domain

abstract type Domain end

abstract type DomainCreator end

function create_domain(::String, ::DomainCreator)
    throw(ErrorException(
        "`create_domain` not implemented for domain $S"
        )
    )
end

end

using .Abstract
# Exported Structures and Functions

# Dependencies
include("types/numbers_game/numbers_game.jl")

# Imports from NumbersGame submodule
using .NumbersGame: NumbersGame

end
