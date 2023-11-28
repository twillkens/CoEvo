using ..Environments: EnvironmentCreator, Environment
using ..Ecosystems: Ecosystem
using ..Domains.PredictionGame: PredictionGameDomain
using ..Environments.ContinuousPredictionGame: ContinuousPredictionGameEnvironmentCreator
using ..Species: get_species
using ..Individuals: get_individuals

struct ModesInteractionSetup{T, E <: EnvironmentCreator}
    species_id::String
    tests::Vector{T}
    environment_creator::E
end

# ModesInteractionSetup GATHERING

function ModesInteractionSetup(
    partner_species_id::String, 
    domain_string::String,
    ecosystem::Ecosystem;
    cohorts::Vector{String} = ["population", "children"],
    episode_length = 16, 
    communication_dimension = 0,
    kwargs...
)
    domain = PredictionGameDomain(domain_string)
    environment_creator = ContinuousPredictionGameEnvironmentCreator(
        domain = domain, 
        episode_length = episode_length, 
        communication_dimension = communication_dimension
    )
    partner_species = get_species(ecosystem, partner_species_id)
    partner_individuals = get_individuals(partner_species, cohorts)
    partner_ids = [individual.id for individual in partner_individuals]
    interaction_setup = ModesInteractionSetup(
        partner_species_id, partner_ids, environment_creator
    )
    return interaction_setup
end

struct ModesIndividualSetup{T, S <: ModesInteractionSetup}
    individual::T
    interaction_setups::Vector{S}
end

function ModesIndividualSetup(
    individual_id::Int,
    ecosystem::Ecosystem,
    interactions::Dict{String, String};
    kwargs...
)
    interaction_setups = [
        ModesInteractionSetup(
            partner_species_id, domain_string, ecosystem; kwargs...
        ) 
        for (partner_species_id, domain_string) in interactions
    ]
    individual_setup = ModesIndividualSetup(individual_id, interaction_setups)
    return individual_setup
end

struct ModesSpeciesSetup{S <: ModesIndividualSetup}
    species_id::String
    individual_setups::Vector{S}
end


function ModesSpeciesSetup(
    species_id::String, 
    ecosystem::Ecosystem,
    filter_tags::Vector{FilterTag},
    interactions::Dict{String, String};
    kwargs...
)
    persistent_ids = [tag.id for tag in filter_tags]
    individual_setups = [
        ModesIndividualSetup(individual_id, ecosystem, interactions; kwargs...) 
        for individual_id in persistent_ids
    ]
    species_setup = ModesSpeciesSetup(species_id, individual_setups)
    return species_setup
end


struct ModesGenerationSetup{S <: ModesSpeciesSetup}
    generation::Int
    species_setups::Vector{S}
end

# ModesGenerationSetup GATHERING

function ModesGenerationSetup(
    generation::Int,
    ecosystem::Ecosystem,
    species_ids::Vector{String},
    all_filter_tags::Dict{String, Vector{FilterTag}},
    all_interactions::Dict{String, Dict{String, String}};
    kwargs...
)
    species_setups = map(species_ids) do (species_id)
        filter_tags = all_filter_tags[species_id]
        interactions = all_interactions[species_id] 
        species_setup = ModesSpeciesSetup(
            species_id, 
            ecosystem,
            filter_tags,
            interactions; 
            kwargs...
        )
        return species_setup
    end
    generation_setup = ModesGenerationSetup(generation, species_setups)
    return generation_setup
end

function ModesGenerationSetup(
    file::JLD2.JLDFile,
    generation_tag_bundle::GenerationTagBundle,
    all_interactions::Dict{String, Dict{String, String}};
    kwargs...
)
    generation = generation_tag_bundle.generation
    ecosystem = load_ecosystem(file, generation)
    species_ids = collect(keys(generation_tag_bundle.all_species_tags))
    all_filter_tags = generation_tag_bundle.all_species_tags
    generation_setup = ModesGenerationSetup(
        generation, ecosystem, species_ids, all_filter_tags, all_interactions; kwargs...
    )
    return generation_setup
end

struct ModesTrialSetup{G <: ModesGenerationSetup}
    archive_directory::String
    trial::Int
    generation_setups::Vector{G}
end

function get_file_path(trial_setup::ModesTrialSetup)
    archive_directory = trial_setup.archive_directory
    trial = trial_setup.trial
    file_path = joinpath(archive_directory, "$trial.jld2")
    return file_path
end

function load_file(trial_setup::ModesTrialSetup, mode::String = "r")
    file_path = get_file_path(trial_setup)
    file = jldopen(file_path, mode)
    return file
end

# ModesTrialSetup GATHERING

function ModesTrialSetup(
    trial::Int = 1,
    archive_directory::String = "/media/tcw/Seagate/two_comp_1/";
    all_interactions::Dict{String, Dict{String, String}} = Dict(
        "Host" => Dict("Parasite" => "PredatorPrey"),
        "Parasite" => Dict("Host" => "PreyPredator")
    ),
    tagging_interval::Int = 50,
    max_generation::Int = typemax(Int),
    kwargs...
)
    file_path = joinpath(archive_directory, "$trial.jld2")
    file = jldopen(file_path, "r")
    generation_tag_bundles = get_generation_tag_bundles(file, tagging_interval, max_generation)
    generation_setups = [
        ModesGenerationSetup(file, generation_tag_bundle, all_interactions; kwargs...) 
        for generation_tag_bundle in generation_tag_bundles
    ]
    modes_setup = ModesTrialSetup(archive_directory, trial, generation_setups)
    close(file)
    return modes_setup
end

# ModesInteractionSetup LOADING

function ModesInteractionSetup(
    interaction_setup::ModesInteractionSetup{Int, <:EnvironmentCreator}, 
    ecosystem::Ecosystem
)
    tests = get_individuals(ecosystem, interaction_setup.tests)
    interaction_setup = ModesInteractionSetup(
        interaction_setup.species_id, tests, interaction_setup.environment_creator
    )
    return interaction_setup
end


function ModesIndividualSetup(
    individual_setup::ModesIndividualSetup{Int, <:ModesInteractionSetup}, 
    ecosystem::Ecosystem
)
    individuals = get_individuals(ecosystem)
    if length(Set(individuals)) < length(individuals)
        individual = rand(individuals)
    else
        individual = first(filter(
            individual -> individual.id == individual_setup.individual, individuals
        ))
    end
    interaction_setups = [
        ModesInteractionSetup(interaction_setup, ecosystem) 
        for interaction_setup in individual_setup.interaction_setups
    ]
    individual_setup = ModesIndividualSetup(individual, interaction_setups)
    return individual_setup
end

# ModesSpeciesSetup LOADING

function ModesSpeciesSetup(
    species_setup::ModesSpeciesSetup{<:ModesIndividualSetup}, ecosystem::Ecosystem
) 
    individual_setups = [
        ModesIndividualSetup(individual_setup, ecosystem) 
        for individual_setup in species_setup.individual_setups
    ]
    species_setup = ModesSpeciesSetup(species_setup.species_id, individual_setups)
    return species_setup
end

# ModesGenerationSetup LOADING

function ModesGenerationSetup(file::JLD2.JLDFile, setup::ModesGenerationSetup)
    ecosystem = load_ecosystem(file, setup.generation)
    species_setups = [
        ModesSpeciesSetup(species_setup, ecosystem) for species_setup in setup.species_setups
    ]
    generation_setup = ModesGenerationSetup(setup.generation, species_setups)
    return generation_setup
end


function ModesGenerationSetup(trial_setup::ModesTrialSetup, generation::Int,)
    file = load_file(trial_setup)
    generation_setup = first(filter(
        setup -> setup.generation == generation, trial_setup.generation_setups
    ))
    println("generation: ", generation)
    println("generation_setup: ", generation_setup)
    generation_setup = ModesGenerationSetup(file, generation_setup)
    close(file)
end
