export inject_noise

using ..Genotypes: BasicGeneticProgramGenotype

function inject_noise(geno::BasicGeneticProgramGenotype, noisedict::Dict{Int, Float64})
    geno = deepcopy(geno)
    for (id, noise) in noisedict
        if !haskey(geno.terminals, id)
            throw(ErrorException("Cannot inject noise into node $id"))
        elseif !isa(geno.terminals[id].val, Float64)
            throw(ErrorException("Cannot inject noise into node $id"))
        else
            node = geno.terminals[id]
            node.val += noise
        end
    end
    return geno
end