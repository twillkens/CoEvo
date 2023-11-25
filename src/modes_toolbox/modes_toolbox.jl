module ModesToolbox

using ..Names
using ..Genotypes.FunctionGraphs
using Serialization
using JLD2
using Distributed

include("observer.jl")
include("prune.jl")
include("load.jl")
include("tag.jl")
include("setup.jl")

# Get input IDs from a single node
function get_input_ids(node::FunctionGraphNode)::Vector{Int}
    return [connection.input_node_id for connection in node.input_connections]
end

# Get input IDs from a vector of nodes
function get_input_ids(nodes::Vector{FunctionGraphNode})::Vector{Int}
    ids = Int[]
    for node in nodes
        append!(ids, get_input_ids(node))
    end
    return ids
end

function modes_evaluate(
    individual::Individual, tests::Vector{<:Individual}, domain_string::String
)
    genotype = individual.genotype
    tests = [test.genotype for test in tests]
    return modes_evaluate(genotype, tests, domain_string)
end

# Update the list of nodes to visit
function update_to_visit(
    to_visit::Vector{Int}, 
    already_visited::Vector{Int}, 
    current_genotype::FunctionGraphGenotype, 
    node_id::Int
)
    inputs = get_input_ids(current_genotype.nodes[node_id])
    forbidden = union(
        current_genotype.input_node_ids, 
        current_genotype.bias_node_ids, 
        current_genotype.output_node_ids, 
        already_visited
    )
    new_to_visit = setdiff(inputs, forbidden)
    return sort!(union(new_to_visit, to_visit), rev=true)
end

function modes_evaluate!(
    genotype::FunctionGraphGenotype, 
    tests::Vector{<:FunctionGraphGenotype},
    environment_creator::ContinuousPredictionGameEnvironmentCreator,
    observer::FunctionGraphModesObserver
)
    fitness = 0.0
    subject = create_phenotype(LinearizedFunctionGraphPhenotypeCreator(), genotype, 1)
    for test in tests
        test = create_phenotype(LinearizedFunctionGraphPhenotypeCreator(), test, 2)
        environment = create_environment(environment_creator, subject, test)
        outcome_set = interact(environment, observer)
        fitness += outcome_set[1]
    end
    return fitness
end

function modes_evaluate!(
    genotype::FunctionGraphGenotype,
    interaction_setup::ModesInteractionSetup,
    observer::FunctionGraphModesObserver,
)
    tests = [partner.genotype for partner in interaction_setup.tests]
    fitness = modes_evaluate!(genotype, tests, interaction_setup.environment_creator, observer)
    return fitness
end

function modes_evaluate!(
    genotype::FunctionGraphGenotype,
    interaction_setups::Vector{<:ModesInteractionSetup},
    observer::FunctionGraphModesObserver,
)
    total_fitness = 0.0
    for interaction_setup in interaction_setups
        interaction_fitness = modes_evaluate!(genotype, interaction_setup, observer)
        total_fitness += interaction_fitness
    end
    return total_fitness
end

struct ModesIndividualReport
    id::Int
    full_genotype::FunctionGraphGenotype
    structurally_pruned_genotype::FunctionGraphGenotype
    modes_pruned_genotype::FunctionGraphGenotype
    full_complexity::Int
    structurally_pruned_complexity::Int
    modes_pruned_complexity::Int
    initial_fitness::Float64
    modes_pruned_fitness::Float64
end

function ModesIndividualReport(
    individual::BasicIndividual{<:FunctionGraphGenotype}, 
    interaction_setups::Vector{<:ModesInteractionSetup}
)
    full_genotype = individual.genotype
    structurally_pruned_genotype = minimize(full_genotype)
    current_genotype = structurally_pruned_genotype

    observer = FunctionGraphModesObserver(to_observe = 1)
    initial_fitness = modes_evaluate!(current_genotype, interaction_setups, observer)
    current_fitness = initial_fitness
    current_observation = create_observation(observer)
    to_visit = sort(current_genotype.hidden_node_ids, rev = true)
    already_visited = Int[]
    while !isempty(to_visit)
        node_to_prune_id = popfirst!(to_visit)
        push!(already_visited, node_to_prune_id)
        node_to_prune_median = current_observation.node_medians[node_to_prune_id]
        pruned_genotype = modes_prune(
            current_genotype, node_to_prune_id, Float64(node_to_prune_median)
        )
        observer = FunctionGraphModesObserver(to_observe = 1)
        pruned_fitness = modes_evaluate!(pruned_genotype, interaction_setups, observer) 
        pruned_observation = create_observation(observer)
        if pruned_fitness >= current_fitness
            current_genotype = minimize(pruned_genotype)
            current_fitness = pruned_fitness
            current_observation = pruned_observation
            to_visit = filter(node -> node ∈ current_genotype.hidden_node_ids, to_visit)
        end
    end
    report = ModesIndividualReport(
        individual.id,
        full_genotype,
        structurally_pruned_genotype,
        current_genotype,
        get_size(full_genotype),
        get_size(structurally_pruned_genotype),
        get_size(current_genotype),
        initial_fitness,
        current_fitness
    )
    return report
end

function ModesIndividualReport(individual_setup::ModesIndividualSetup)
    report = ModesIndividualReport(
        individual_setup.individual, individual_setup.interaction_setups
    )
    return report
end

struct ModesSpeciesReport{R <: ModesIndividualReport}
    species_id::String
    individual_reports::Vector{R}
    maximum_complexity::Int
end

function ModesSpeciesReport(species_setup::ModesSpeciesSetup)
    species_id = species_setup.species_id
    individual_setups = species_setup.individual_setups
    individual_reports = [
        ModesIndividualReport(individual_setup) 
        for individual_setup in individual_setups
    ]
    maximum_complexity = maximum(
        report.modes_pruned_complexity for report in individual_reports
    )
    report = ModesSpeciesReport(species_id, individual_reports, maximum_complexity)
    return report
end

struct ModesGenerationReport{R <: ModesSpeciesReport}
    generation::Int
    species_reports::Vector{R}
    maximum_complexity::Int
end

function ModesGenerationReport(file::JLD2.JLDFile, generation_setup::ModesGenerationSetup)
    generation_setup = ModesGenerationSetup(file, generation_setup)
    species_reports = [
        ModesSpeciesReport(species_setup) for species_setup in generation_setup.species_setups
    ]
    maximum_complexity = maximum(
        report.maximum_complexity for report in species_reports
    )
    report = ModesGenerationReport(
        generation_setup.generation, species_reports, maximum_complexity
    )
    return report
end

struct ModesTrialReport{R <: ModesGenerationReport}
    trial::Int
    generation_reports::Vector{R}
    complexities::Vector{Int}
    generations::Vector{Int}
end

function ModesTrialReport(trial_setup::ModesTrialSetup)
    file = load_file(trial_setup)
    generation_reports = [
        ModesGenerationReport(file, generation_setup) 
        for generation_setup in trial_setup.generation_setups
    ]
    complexities = [report.maximum_complexity for report in generation_reports]
    generations = [report.generation for report in generation_reports]
    report = ModesTrialReport(
        trial_setup.trial, generation_reports, complexities, generations
    )
    close(file)
    return report
end

function ModesTrialReport(
    trial::Int = 1,
    archive_directory::String = "/media/tcw/Seagate/two_comp/";
    kwargs...
)
    trial_setup = ModesTrialSetup(trial, archive_directory; kwargs...)
    report = ModesTrialReport(trial_setup)
    return report
end


end