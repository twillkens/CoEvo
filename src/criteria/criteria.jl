"""
    Criteria

A module that defines criteria for optimization or evaluation processes. Provides abstractions for specifying whether to maximize or minimize a given objective.

## Types

- `Criterion`: 
  An abstract type that serves as a base for all criteria types.
  
- `Maximize`: 
  A subtype of `Criterion` indicating that the objective should be maximized.
  
- `Minimize`: 
  A subtype of `Criterion` indicating that the objective should be minimized.

## Usage

When defining an optimization or evaluation task, use the appropriate subtype (`Maximize` or `Minimize`) to specify the direction of optimization.

"""
module Criteria

export Criterion, Maximize, Minimize

abstract type Criterion end

struct Maximize <: Criterion end

struct Minimize <: Criterion end

end