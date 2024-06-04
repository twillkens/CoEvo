export create_environment, get_phenotypes, step!, get_outcome_set, is_active, observe!

using ..Abstract

function create_environment(
    environment_creator::EnvironmentCreator, phenotype_1::Phenotype, phenotype_2::Phenotype
)
    environment_creator = typeof(environment_creator)
    phenotype_1 = typeof(phenotype_1)
    phenotype_2 = typeof(phenotype_2)
    error("create_environment not implemented for $environment_creator, $phenotype_1, $phenotype_2")
end

function create_environment(
    environment_creator::EnvironmentCreator, 
    phenotypes::Vector{<:Phenotype},
) 
    if length(phenotypes) != 2
        throw(ErrorException("Only two-entity interactions are supported for now."))
    end
    create_environment(environment_creator, phenotypes[1], phenotypes[2])
end

function get_phenotypes(environment::Environment)::Vector{Pair{Int, Phenotype}}
    throw(ErrorException(
        "`get_phenotypes` not implemented for $environment"
        )
    )
end

function step!(environment::Environment)::Nothing
    environment = typeof(environment)
    error("step! not implemented for $environment")
end

function get_outcome_set(environment::Environment)
    environment = typeof(environment)
    error("get_outcome_set not implemented for $environment")
end

function is_active(environment::Environment)
    environment = typeof(environment)
    error("is_active not implemented for $environment")
end
