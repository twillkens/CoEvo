export inject_noise

using ..Genotypes: BasicGeneticProgramGenotype

function inject_noise(geno::BasicGeneticProgramGenotype, noisedict::Dict{Int, Float64})
    geno = deepcopy(geno)
    for (id, node) in geno.terms
        if isa(node.val, Float64)
            node.val += noisedict[id]
        end
    end
    return geno
end