
mutable struct GPAgent <: AbstractAgent
    key::String
    popkey::String
    interactions::Dict{String, Bool}
    tape::Vector{Float64}
    expr::Expr
    otape::Vector{Float64}
end

function GPAgent(indiv::GPIndiv)
    GPAgent(indiv.key, indiv.keydict["pop"],
            indiv.interactions, indiv.tape, indiv.expr, Float64[])
end