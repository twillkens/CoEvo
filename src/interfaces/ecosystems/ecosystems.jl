export create_ecosystem, update_ecosystem!, convert_to_dictionary, convert_from_dictionary

using ..Abstract

function create_ecosystem(ecosystem_creator::EcosystemCreator)::Ecosystem
    error("`create_environment` not implemented for $ecosystem_creator")
end

function update_ecosystem!(
    ecosystem::Ecosystem, ecosystem_creator::EcosystemCreator, state::State
)
    ecosystem_type = typeof(ecosystem)
    ecosystem_creator_type = typeof(ecosystem_creator)
    state_type = typeof(state)
    error(
        "`update_ecosystem!` not implemented for $ecosystem_type, $ecosystem_creator_type, $state_type"
    )
end

function convert_to_dictionary(ecosystem::Ecosystem)
    error("convert_to_dictionary not implemented for $ecosystem")
end

function convert_from_dictionary(
    ecosystem_creator::EcosystemCreator, 
    species_creator::SpeciesCreator,
    individual_creator::IndividualCreator,
    genotype_creator::GenotypeCreator,
    phenotype_creator::PhenotypeCreator,
    dict::Dict
)
    ecosystem_creator_type = typeof(ecosystem_creator)
    error("convert_from_dictionary not implemented for $ecosystem_creator_type and $dict")
end