module Criteria

export NullCriterion, Maximize, Minimize

using ...CoEvo.Abstract: Criterion

struct NullCriterion <: Criterion end

struct Maximize <: Criterion end

struct Minimize <: Criterion end

end