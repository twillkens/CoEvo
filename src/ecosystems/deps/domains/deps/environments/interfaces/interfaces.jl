module Interfaces

export create_environment, next!, refresh!, assign_entities!, get_outcomes, is_active

using ..Abstract: Environment, EnvironmentCreator, Phenotype

function create_environment(env_creator::EnvironmentCreator, domain_id::String)::Environment
    throw(ErrorException(
        "`create_environment` not implemented for $env "
        )
    )
end

function next!(env::Environment)::Nothing
    throw(ErrorException(
        "`next!` not implemented for env $env"
        )
    )
end

function refresh!(env::Environment)::Nothing
    throw(ErrorException(
        "`refresh!` not implemented for env $env"
        )
    )
end

function assign_entities!(env::Environment, phenotypes::Vector{<:Phenotype})::Nothing
    throw(ErrorException(
        "`assign_entities!` not implemented for env $env, phenotypes $phenotypes"
        )
    )
end

function get_outcomes(env::Environment)::Vector{Float64}
    throw(ErrorException(
        "`get_outcomes` not implemented for env $env"
        )
    )
end

function is_active(env::Environment)::Bool
    throw(ErrorException(
        "`is_active` not implemented for env $env"
        )
    )
end

end