export PairRecipe, RoleConfig, MixRecipe

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

struct MixRecipe{D <: Domain, C <: PhenoConfig} <: Recipe
    n::Int
    domain::D
    outcome::Type{<:Outcome}
    entityroles::Set{EntityRole{C}}
end

function MixRecipe(n::Int, o::Order, entityroles::Set{EntityRole{C}}) where {C <: PhenoConfig}
    MixRecipe(n, o.domain, o.outcome, entityroles)
end

function(r::MixRecipe)(phenodict::Dict{String, P}) where {P <: Phenotype}
    rolephenos = Dict{Symbol, P}()
    for entityrole in r.entityroles
        pheno = phenodict[entityrole.key]
        rolephenos[entityrole.role] = pheno
    end
    SetMix(r.n, r.domain, r.outcome, rolephenos)
end

function Set{String}(recipe::MixRecipe)
    Set([entityrole.key for entityrole in recipe.entityroles])
end

struct PairRecipe{D <: Domain, S <: PhenoConfig, T <: PhenoConfig} <: Recipe
    n::Int
    domain::D
    outcome::Type{<:Outcome}
    subject_key::String
    subject_cfg::S
    test_key::String
    test_cfg::T
end

function PairRecipe(n::Int, order::PairOrder,
                    subject_geno::Genotype,
                    test_geno::Genotype)
    PairRecipe(n, order.domain,
               order.outcome,
               subject_geno.key, order.subjects_cfg,
               test_geno.key, order.tests_cfg)
end

function(r::PairRecipe)(phenodict::Dict{String, Phenotype})
    subject_pheno = phenodict[r.subject_key]
    test_pheno = phenodict[r.test_key]
    PairMix(r.n, r.domain, r.outcome, subject_pheno, test_pheno)
end

function Set{String}(recipe::PairRecipe)
    Set([recipe.subject_key, recipe.test_key])
end


function(o::PairOrder)(pops::Set{<:Population})
    popdict = Dict{String, Population}(pops)
    subjects = popdict[o.subjects_key]
    tests = popdict[o.tests_key]
    (o)(subjects, tests)
end

include("allvsall.jl")
include("sampler.jl")
