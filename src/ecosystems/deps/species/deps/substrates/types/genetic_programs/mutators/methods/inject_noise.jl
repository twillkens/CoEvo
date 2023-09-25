export inject_noise

using Random: AbstractRNG, randn

# Generate a dictionary of random noise values for each real-valued terminal in the genotype
# and inject the noise into a copy of the genotype. Uses the BasicGeneticProgramMutator noise_std field.
function inject_noise(
    rng::AbstractRNG, 
    gene_id_counter::Counter, 
    m::BasicGeneticProgramMutator, 
    geno::BasicGeneticProgramGenotype
)
    noisedict = Dict{Int, Float64}()
    injectable_ids = [id for (id, node) in geno.terms if isa(node.val, Float64)]
    noisevec = randn(rng, length(injectable_ids)) * m.noise_std
    noisedict = Dict(zip(injectable_ids, noisevec))
    inject_noise(geno, noisedict)
end