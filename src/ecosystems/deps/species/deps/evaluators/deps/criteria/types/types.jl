module Types

using ..Abstract: Criterion

"""
    NullCriterion

A neutral criterion, often used as a placeholder or default when no specific optimization direction 
is provided.
"""
struct NullCriterion <: Criterion end

"""
    Maximize

A criterion that signifies the objective of maximizing a particular value or metric.
"""
struct Maximize <: Criterion end

"""
    Minimize

A criterion that signifies the objective of minimizing a particular value or metric.
"""
struct Minimize <: Criterion end

end