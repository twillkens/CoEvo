export Mix

struct Mix{D <: Domain, P <: Phenotype}
    n::Int
    domain::D
    outcome::Type{<:Outcome}
    rolephenos::Dict{Symbol, P}
end

function(m::Mix)()
    m.outcome(m.n, m.domain; m.rolephenos...) 
end

function add_pheno!(entityrole::EntityRole,
                    genodict::Dict{String, Genotype},
                    phenodict::Dict{String, Phenotype},)
    if entityrole.key ∉ keys(phenodict)
        geno = genodict[entityrole.key]
        pheno = (entityrole.phenocfg)(geno)
        phenodict[entityrole.key] = pheno
    end
end

function add_pheno!(recipe::Recipe,
                    genodict::Dict{String, Genotype},
                    phenodict::Dict{String, Phenotype},)
    [add_pheno!(entityrole, genodict, phenodict) for entityrole in recipe.entityroles]
end

function add_pheno!(key::String,
                    pheno_cfg::PhenoConfig,
                    genodict::Dict{String, Genotype},
                    phenodict::Dict{String, Phenotype},)
    if key ∉ keys(phenodict)
        geno = genodict[key]
        pheno = (pheno_cfg)(geno)
        phenodict[key] = pheno
    end
end


function Dict{String, Phenotype}(recipes::Set{<:Recipe}, genodict::Dict{String, Genotype},)
    phenodict = Dict{String, Phenotype}()
    [add_pheno!(recipe, genodict, phenodict) for recipe in recipes]
    phenodict
end

function Set{Mix}(recipes::Set{<:Recipe}, phenodict::Dict{String, Phenotype},)
    Set([recipe(phenodict) for recipe in recipes])
end

function Set{Mix}(recipes::Set{<:Recipe},
                  genodict::Dict{String, Genotype},)
    phenodict = Dict{String, Phenotype}(recipes, genodict)
    Set{Mix}(recipes, phenodict)
end