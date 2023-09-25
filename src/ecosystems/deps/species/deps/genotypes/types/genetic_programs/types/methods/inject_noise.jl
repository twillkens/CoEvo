export inject_noise

# Mutate the genotype by adding random noise to real-valued terminals
function inject_noise(geno::BasicGeneticProgramGenotype, noisedict::Dict{Int, Float64})
    geno = deepcopy(geno)
    for (gid, noise) in noisedict
        node = get_node(geno, gid)
        if isa(node.val, Float64)
            node.val += noise
        else
            throw(ErrorException("Cannot inject noise into non-Float64 node"))
        end
    end
    geno
end

# Generate a dictionary of random noise values for each real-valued terminal in the genotype
# and inject the noise into a copy of the genotype. Uses the BasicGeneticProgramMutator noise_std field.
function inject_noise(rng::AbstractRNG, ::SpawnCounter, m::BasicGeneticProgramMutator, geno::BasicGeneticProgramGenotype)
    noisedict = Dict{Int, Float64}()
    injectable_gids = [gid for (gid, node) in geno.terms if isa(node.val, Float64)]
    noisevec = randn(rng, length(injectable_gids)) * m.noise_std
    noisedict = Dict(zip(injectable_gids, noisevec))
    inject_noise(geno, noisedict)
end