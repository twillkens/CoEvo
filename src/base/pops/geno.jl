export GenoPop, GenoPopConfig

struct GenoPop <: Population
    key::String
    curr_id::Int
    genos::Set{Genotype}
end

function GenoPop(pop::GenoPop, ::Set{<:Outcome}, curr_id::Int, genos::Set{<:Genotype})
    GenoPop(pop.key, curr_id, genos)
end

Base.@kwdef struct GenoPopConfig{C <: GenoConfig} <: PopConfig
    key::String
    n_genos::Int
    geno_cfg::C
end

function(g::GenoPopConfig)()
    genos = Set([g.geno_cfg(join([g.key, i], KEY_SPLIT_TOKEN)) for i in 1:g.n_genos])
    GenoPop(g.key, g.n_genos + 1, genos)
end

function Dict{String, Genotype}(pop::GenoPop)
    Dict{String, Genotype}([geno.key => geno for geno in pop.genos])
end

function Dict{String, Genotype}(pops::Set{GenoPop})
    merge([Dict{String, Genotype}(pop) for pop in pops]...)
end