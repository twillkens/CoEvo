export Veteran, VetSpecies

struct Veteran{I <: Individual, R <: Result}
    indiv::I
    results::Set{R}
end

struct VetSpecies{V <: Veteran}
    spkey::String
    pop::Set{V}
    parents::Vector{Int}
    children::Set{V}
end