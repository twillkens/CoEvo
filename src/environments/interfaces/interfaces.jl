export create_environment, get_phenotypes, step!, get_outcome_set, is_active, observe!

function create_environment(
    environment_creator::EnvironmentCreator, 
    phenotypes::Vector{Phenotype},
    phenotype_ids::Vector{Int},
) #where {P <: Phenotype}
    throw(ErrorException(
        "`create_environment` not implemented for $environment_creator and $phenotypes with ids $phenotype_ids"
        )
    )
end

function get_phenotypes(environment::Environment)::Vector{Pair{Int, Phenotype}}
    throw(ErrorException(
        "`get_phenotypes` not implemented for $environment"
        )
    )
end

function observe!(observer::Observer, environment::Environment)
    error("`observe!` not implemented for $(typeof(observer)) and $(typeof(environment))")
end

function observe!(observer::PhenotypeObserver, environment::Environment)
    for (id, phenotype) in get_phenotypes(environment)
        observe!(observer, phenotype, id)
    end
end

function step!(environment::Environment)::Nothing
    throw(ErrorException(
        "`next!` not implemented for environment $environment"
        )
    )
end

function get_outcome_set(environment::Environment)::Vector{Float64}
    throw(ErrorException(
        "`get_outcomes` not implemented for environment $environment"
        )
    )
end

function is_active(environment::Environment)::Bool
    throw(ErrorException(
        "`is_active` not implemented for environment $environment"
        )
    )
end

function observe!(environment::Environment, observer::NullObserver)
    return nothing
end

