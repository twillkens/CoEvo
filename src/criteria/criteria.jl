module Criteria

export Criterion, Maximize, Minimize

abstract type Criterion end

struct Maximize <: Criterion end

struct Minimize <: Criterion end

end