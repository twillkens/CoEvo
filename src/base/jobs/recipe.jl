Base.@kwdef struct PopRole{C <: PhenoConfig}
    role::Symbol
    phenocfg::C
end

struct IndivRole{C <: PhenoConfig} 
    key::String
    role::Symbol
    phenocfg::C
end

function IndivRole(geno::Genotype, poprole::PopRole{C}) where {C <: PhenoConfig}
    IndivRole(geno.key, poprole.role, poprole.phenocfg)
end

struct Recipe{D <: Domain}
    rid::Int
    domain::D
    outcome::Type{<:Outcome}
    iroles::Set{<:IndivRole}
end

function Recipe(n::Int, o::Order, iroles::Set{IndivRole{C}}) where {C <: PhenoConfig}
    Recipe(n, o.domain, o.outcome, iroles)
end

function(r::Recipe)(phenodict::Dict{String, P}) where {P <: Phenotype}
    rolephenos = Dict{Symbol, P}()
    for irole in r.iroles
        pheno = phenodict[irole.key]
        rolephenos[irole.role] = pheno
    end
    Mix(r.n, r.domain, r.outcome, rolephenos)
end

function Set{String}(recipe::Recipe)
    Set([irole.key for irole in recipe.iroles])
end