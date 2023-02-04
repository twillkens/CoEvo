export VAllvsAllOrder, getroles
export PopRole, EntityRole, Recipe

Base.@kwdef struct PopRole{C <: PhenoConfig}
    role::Symbol
    phenocfg::C
end

struct EntityRole{C <: PhenoConfig} 
    key::String
    role::Symbol
    phenocfg::C
end

function EntityRole(geno::Genotype, poprole::PopRole{C}) where {C <: PhenoConfig}
    EntityRole(geno.key, poprole.role, poprole.phenocfg)
end

struct Recipe{D <: Domain}
    rid::Int
    domain::D
    outcome::Type{<:Outcome}
    entityroles::Set{<:EntityRole}
end

function Recipe(n::Int, o::Order, entityroles::Set{EntityRole{C}}) where {C <: PhenoConfig}
    Recipe(n, o.domain, o.outcome, entityroles)
end

function(r::Recipe)(phenodict::Dict{String, P}) where {P <: Phenotype}
    rolephenos = Dict{Symbol, P}()
    for entityrole in r.entityroles
        pheno = phenodict[entityrole.key]
        rolephenos[entityrole.role] = pheno
    end
    Mix(r.n, r.domain, r.outcome, rolephenos)
end

function Set{String}(recipe::Recipe)
    Set([entityrole.key for entityrole in recipe.entityroles])
end
Base.@kwdef struct VAllvsAllOrder{D <: Domain, P <: PhenoConfig} <: Order
    domain::D
    outcome::Type{<:Outcome}
    roles::Dict{String, PopRole{P}}
end

function getroles(o::Order, sp::Species) 
    return [EntityRole(indiv.geno, o.roles[sp.key]) for indiv in union(sp.pop, sp.children)]
end

function(o::VAllvsAllOrder)(sp1::Species, sp2::Species)
    roles1 = getroles(o, sp1)
    roles2 = getroles(o, sp2)
    pairs = unique(Set, Iterators.filter(allunique,
                   Iterators.product([roles1, roles2])))
    Set([MixRecipe(mixn, o, Set(entity_roleset))
        for (mixn, entity_roleset) in enumerate(pairs)])
end