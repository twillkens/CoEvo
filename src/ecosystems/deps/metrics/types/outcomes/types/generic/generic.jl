module Generic

export AbsoluteError

using ...Outcomes.Abstract: OutcomeMetric

Base.@kwdef struct AbsoluteError <: OutcomeMetric
    name::String = "AbsoluteError"
end

end