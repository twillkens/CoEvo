module Interfaces

export create_environment, next!, get_outcome_set, is_active, observe!

using ..Environments.Abstract: Environment, EnvironmentCreator
using ....Species.Phenotypes.Abstract: Phenotype
using ...Interactions.Observers.Abstract: Observer


function create_environment(
    env_creator::EnvironmentCreator, 
    domain::String,
    phenotypes::Vector{<:Phenotype}
)::Environment
    throw(ErrorException(
        "`create_environment` not implemented for $env_creator "
        )
    )
end

function observe!(environment::Environment, observer::Observer)
    error("`observe!`` not implemented for $(typeof(environment)), $(typeof(observer))")
end


function next!(env::Environment)::Nothing
    throw(ErrorException(
        "`next!` not implemented for env $env"
        )
    )
end

function get_outcome_set(env::Environment)::Vector{Float64}
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