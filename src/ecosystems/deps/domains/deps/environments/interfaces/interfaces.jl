module Interfaces

export create_environment, next!, refresh!, assign_entities!, get_outcomes

using ..Abstract: Environment, EnvironmentCreator, Phenotype

function create_environment(env_creator::EnvironmentCreator, domain_id::String)
    throw(ErrorException(
        "`create_environment` not implemented for $env "
        )
    )
end

function next!(env::Environment)
    throw(ErrorException(
        "`next!` not implemented for env $env"
        )
    )
end

function refresh!(env::Environment)
    throw(ErrorException(
        "`refresh!` not implemented for env $env"
        )
    )
end

function assign_entities!(env::Environment, phenotypes::Vector{<:Phenotype})
    throw(ErrorException(
        "`assign_entities!` not implemented for env $env, phenotypes $phenotypes"
        )
    )
end

function get_outcomes(env::Environment)
    throw(ErrorException(
        "`get_outcomes` not implemented for env $env"
        )
    )
end

end