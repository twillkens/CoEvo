export Species, ScoreOutcome

struct Species{I <: Individual} <: Population
    spkey::String
    pop::Set{I}
    parents::Vector{I}
    children::Set{I}
end

struct ScoreOutcome <: Outcome
    mixn::Int
    genokey::String
    testkey::String
    role::Symbol
    score::Float64
end