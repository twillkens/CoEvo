"""
    Criteria

The `Criteria` module focuses on decision-making utilities. It provides a set of criterion-based types 
that dictate optimization objectives or offer neutral decision criteria.

# Key Types
- [`NullCriterion`](@ref): Represents a neutral criterion, often used as a default or placeholder.
- [`Maximize`](@ref): Signifies an objective to maximize a certain value or metric.
- [`Minimize`](@ref): Signifies an objective to minimize a certain value or metric.

# Interactions
These criteria types extend from the abstract type `Criterion` defined in the `...CoEvo.Abstract` module. 
They can be utilized across various components of the coevolutionary system to steer decision-making based 
on the desired optimization goals.

# Usage
Import the required criterion type from the `Criteria` module when setting objectives or decision-making rules.

# Exports
The module exports the following types: `NullCriterion`, `Maximize`, and `Minimize`.
"""
module Criteria


end
