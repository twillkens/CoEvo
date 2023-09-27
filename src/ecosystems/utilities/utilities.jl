"""
    Counters

The `Counters` module offers utilities for maintaining and incrementing numeric counters. 
It's useful for generating sequences of numbers, such as unique identifiers.

# Key Types
- [`Counter`](@ref): A mutable structure that represents a counter initialized with a default or specified value.
  
# Main Functions
- [`next!`](@ref): Increments the `Counter` value by one or a specified number and returns the current value or a sequence of values.

# Usage
To generate a sequence of unique numbers, instantiate a `Counter` and use the `next!` function to increment its value. 

# Exports
The module exports the following types and functions: `Counter`, and `next!`.
"""

module Utilities

include("types/counters.jl")
include("types/statistics.jl")


end
