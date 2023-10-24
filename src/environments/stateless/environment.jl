export StatelessEnvironment, StatelessEnvironmentCreator

struct StatelessEnvironment{D, P <: Phenotype} <: Environment{D}
    domain::D
    phenotypes::Vector{P}
end

Base.@kwdef struct StatelessEnvironmentCreator{D} <: EnvironmentCreator{D}
    domain::D
end

function create_environment(
    environment_creator::StatelessEnvironmentCreator{D},
    phenotypes::Vector{Phenotype}
) where {D <: Domain}
    environment = StatelessEnvironment(
        environment_creator.domain,
        phenotypes
    )
    return environment
end

function is_active(::StatelessEnvironment)
    return false
end