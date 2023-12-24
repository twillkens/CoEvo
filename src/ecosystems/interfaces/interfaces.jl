export create_ecosystem, get_individuals, get_species

import ..Individuals: get_individuals

using ..Results: Result
#using ..Reporters: Report

function create_ecosystem(ecosystem_creator::EcosystemCreator)::Ecosystem
    throw(ErrorException(
        "`create_environment` not implemented for $ecosystem_creator"
        )
    )
end

#function create_ecosystem(
#    generation::Int, 
#    ecosystem_creator::EcosystemCreator,
#    previous_ecosystem::Ecosystem,
#    results::Vector{Result},    
#    reports::Vector{Report}
#)::Ecosystem
#    throw(ErrorException(
#        "`create_ecosystem` not implemented for $ecosystem_creator"
#        )
#    )
#end

#function evolve!(eco::Ecosystem, ecosystem_creator::EcosystemCreator, n_generations::Int)::Nothing
#    throw(ErrorException(
#        "`evolve!` not implemented for $eco"
#        )
#    )
#end

function get_individuals(ecosystem::Ecosystem, ids::Vector{Int})
    throw(ErrorException(
        "`get_individuals` not implemented for $ecosystem with ids $ids"
        )
    )
end

function get_species(ecosystem::Ecosystem, species_id::String)
    throw(ErrorException(
        "`get_species` not implemented for $ecosystem with species id $species_id"
        )
    )
end
