module Common



function identity(
    rng::AbstractRNG, 
    gene_id_counter::Counter, 
    geno::GeneticProgramGenotype,
    functions::Dict{FuncAlias, Int},
    terminals::Dict{Terminal, Int},
    ::Float64,
)
    return geno
end

end