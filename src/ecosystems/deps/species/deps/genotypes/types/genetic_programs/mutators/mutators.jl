module Mutators

export BasicGeneticProgramMutator

Base.@kwdef struct BasicGeneticProgramMutator <: Mutator
    # Number of structural changes to perform per generation
    nchanges::Int = 1
    # Uniform probability of each type of structural change
    probs::Dict{Function, Float64} = Dict(
        add_function => 1 / 4,
        remove_function => 1 / 4,
        splice_function => 1 / 4
        swap_node => 1 / 4,
    )
    terminals::Dict{Terminal, Int} = Dict(
        :read => 1, 
        0.0 => 1, 
    )
    functions::Dict{FuncAlias, Int} = Dict([
        (protected_sine, 1), 
        (+, 2), 
        (-, 2), 
        (*, 2),
        (iflt, 4),
    ])
    noise_std::Float64 = 0.1
end

function(m::BasicGeneticProgramMutator)(rng::AbstractRNG, sc::SpawnCounter, geno::BasicGeneticProgramGenotype,) 
    fns = sample(rng, collect(keys(m.probs)), Weights(collect(values(m.probs))), m.nchanges)
    for fn in fns
        geno = fn(rng, sc, m, geno)
    end
    if geno.root_gid ∉ keys(all_nodes(geno))
        throw(ErrorException("Root node not in genotype"))
    end
    geno = inject_noise(rng, sc, m, geno)
    if geno.root_gid ∉ keys(all_nodes(geno))
        throw(ErrorException("Root node not in genotype after noise"))
    end
    geno
end


end