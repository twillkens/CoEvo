module Interfaces

export create_ecosystem, evolve!

using ..Abstract: Ecosystem, EcosystemCreator
using ..Performers.Results.Abstract: Result
using ..Reporters.Abstract: Report

function create_ecosystem(eco_creator::EcosystemCreator)::Ecosystem
    throw(ErrorException(
        "`create_environment` not implemented for $env "
        )
    )
end

function create_ecosystem(
    generation::Int, 
    ecosystem_creator::EcosystemCreator,
    previous_ecosystem::Ecosystem,
    results::Vector{Result},    
    reports::Vector{Report}
)::Ecosystem
    throw(ErrorException(
        "`create_environment` not implemented for $env "
        )
    )
end

function evolve!(eco::Ecosystem, eco_creator::EcosystemCreator, n_gen::Int)::Nothing
    throw(ErrorException(
        "`evolve!` not implemented for $eco"
        )
    )
end

end