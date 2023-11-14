export StatelessEnvironment, StatelessEnvironmentCreator

struct StatelessEnvironment{D, P1 <: Phenotype, P2 <: Phenotype} <: Environment{D}
    domain::D
    entity_1::P1
    entity_2::P2
end

Base.@kwdef struct StatelessEnvironmentCreator{D} <: EnvironmentCreator{D}
    domain::D
end

function create_environment(
    environment_creator::StatelessEnvironmentCreator{D}, 
    phenotype_1::Phenotype, 
    phenotype_2::Phenotype, 
) where {D <: Domain}
    environment = StatelessEnvironment(environment_creator.domain, phenotype_1, phenotype_2)
    return environment
end

function is_active(::StatelessEnvironment)
    return false
end

function get_phenotypes(environment::StatelessEnvironment)
    return [environment.entity_1, environment.entity_2]
end