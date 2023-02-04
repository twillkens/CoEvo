export Species, ScoreOutcome

struct Species{I <: Individual}
    spkey::String
    pop::Set{I}
    parents::Vector{I}
    children::Set{I}
end
