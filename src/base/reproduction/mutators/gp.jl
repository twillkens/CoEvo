
Base.@kwdef struct GPMutator <: Mutator
    nchanges::Int = 1
    probs::Dict{Function, Float64} = Dict(
        addfunc => 0.1,
        rmfunc => 0.1,
    )
    weight_factor::Float64 = 0.1
end

