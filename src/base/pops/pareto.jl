export ParetoPop, ParetoPopConfig

struct ParetoPop{T <: Genotype, O <: Outcome} <: Population
    key::String
    curr_id::Int
    genos::Set{T}
    parents::Set{T}
    children::Set{T}
    parent_outcomes::Set{O}
end

Base.@kwdef struct ParetoPopConfig{C <: GenoConfig} <: PopConfig
    key::String
    n_parents::Int
    n_children::Int
    geno_cfg::C
end


function make_dummies(genos::Set{<:Genotype})
    Set([ScalarOutcome(i, Set([ScalarResult(g.key, :dummy, 1.0)]))
        for (i, g) in enumerate(genos)])
end

function(g::ParetoPopConfig)()
    parents = Set([g.geno_cfg(join([g.key, i], KEY_SPLIT_TOKEN)) for i in 1:g.n_parents])
    children = Set([g.geno_cfg(join([g.key, i], KEY_SPLIT_TOKEN)) for i in 1:g.n_children])
    curr_id = g.n_parents + g.n_children + 1
    ParetoPop(g.key, curr_id, union(parents, children), parents, children, make_dummies(parents))
end

function Dict{String, Genotype}(pop::ParetoPop)
    parents_dict = Dict{String, Genotype}([geno.key => geno for geno in pop.parents])
    children_dict = Dict{String, Genotype}([geno.key => geno for geno in pop.children])
    merge(parents_dict, children_dict)
end

function Dict{String, Genotype}(pops::Set{ParetoPop})
    merge([Dict{String, Genotype}(pop) for pop in pops]...)
end
