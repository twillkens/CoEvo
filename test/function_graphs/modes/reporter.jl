
Base.@kwdef mutable struct ModesReporter{S <: AbstractSpecies} <: Reporter
    modes_interval::Int = 10
    tag_dictionary::Dict{Int, Int} = Dict{Int, Int}()
    persistent_ids::Set{Int} = Set{Int}()
    all_species::Vector{S} = AbstractSpecies[]
    previous_modes_generation::Int = 0
    previous_modes_genotypes::Set{Genotype} = Set{Genotype}()
    all_modes_genotypes::Set{Genotype} = Set{Genotype}()
end

function update_species_list(reporter::ModesReporter, all_species::Vector{<:AbstractSpecies})
    reporter.all_species = copy(all_species)
end

function reset_tag_dictionary(reporter::ModesReporter)
    empty!(reporter.tag_dictionary)
end

function update_tag_dictionary(reporter::ModesReporter, all_species::Vector{<:AbstractSpecies})
    individuals = vcat([get_individuals(species) for species in all_species]...)
    for (tag, individual) in enumerate(individuals)
        reporter.tag_dictionary[individual.id] = tag
    end
end
# Function to extract all individuals from a list of species
function extract_individuals(all_species::Vector{<:AbstractSpecies})
    return vcat([get_individuals(species) for species in all_species]...)
end

# Function to update tags for individuals
function update_tags(reporter::ModesReporter, individuals::Vector{<:Individual})
    persistent_tags = Set{Int}()
    for individual in individuals
        parent_id = first(individual.parent_ids)
        if haskey(reporter.tag_dictionary, parent_id)
            tag = reporter.tag_dictionary[parent_id]
            push!(persistent_tags, tag)
            reporter.tag_dictionary[individual.id] = tag
        end
    end
    return persistent_tags
end

# Function to update persistent IDs
function update_persistent_ids(reporter::ModesReporter, persistent_tags::Set{Int})
    empty!(reporter.persistent_ids)
    all_individuals = extract_individuals(reporter.all_species)
    for individual in all_individuals
        tag = reporter.tag_dictionary[individual.id]
        if tag in persistent_tags
            push!(reporter.persistent_ids, individual.id)
        end
    end
end

# Main function calling the modularized components
function update_persistent_ids(reporter::ModesReporter, all_species::Vector{<:AbstractSpecies})
    individuals = extract_individuals(all_species)
    persistent_tags = update_tags(reporter, individuals)
    update_persistent_ids(reporter, persistent_tags)
end

function get_maximum_complexity(species::AbstractSpecies)
    individuals = get_individuals(species)
    maximum_complexity = get_maximum_complexity(individuals)
    return maximum_complexity
end

function get_maximum_complexity(all_species::Vector{<:AbstractSpecies})
    maximum_complexity = maximum([get_maximum_complexity(species) for species in all_species])
    return maximum_complexity
end

function calculate_novelty!(reporter::ModesReporter, individuals::Vector{<:Individual})
    genotypes = [individual.genotype for individual in individuals]
    genotypes = Set(genotypes)
    new_genotypes = setdiff(genotypes, reporter.all_modes_genotypes)
    novelty = length(new_genotypes)
    union!(reporter.all_modes_genotypes, new_genotypes)
    return novelty
end

function calculate_change!(reporter::ModesReporter, individuals::Vector{<:Individual})
    genotypes = [individual.genotype for individual in individuals]
    genotypes = Set(genotypes)
    different_genotypes = setdiff(genotypes, reporter.previous_modes_genotypes)
    change = length(different_genotypes)
    reporter.previous_modes_genotypes = genotypes
    return change
end

Base.@kwdef struct ModesMetric <: Metric
    name::String = "modes"
    to_print::Union{String, Vector{String}} = ["novelty", "change", "complexity"]
    to_save::Union{String, Vector{String}} = "all"
end

function quick_print(generation, modes_complexity, species_complexity, novelty, change)
    gen_string = "GENERATION: $generation"
    modes_complexity_string = "MODES_COMPLEXITY: $modes_complexity"
    species_complexity_string = "SPECIES_COMPLEXITY: $species_complexity"
    novelty_string = "NOVELTY: $novelty"
    change_string = "CHANGE: $change"
    print_report = [
        gen_string, modes_complexity_string, species_complexity_string, novelty_string, change_string
    ]
    println(join(print_report, ", "))
end

function create_report(
    reporter::ModesReporter, 
    trial::Int,
    generation::Int, 
    species_creators::Vector{<:SpeciesCreator},
    job_creator::JobCreator,
    performer::Performer,
    random_number_generator::AbstractRNG,
    all_species::Vector{<:AbstractSpecies}
)
    if generation == 1
        update_species_list(reporter, all_species)
        reset_tag_dictionary(reporter)
        update_tag_dictionary(reporter, all_species)
        reporter.persistent_ids = get_all_ids(all_species)
        reporter.previous_modes_generation = generation
    elseif generation % reporter.modes_interval == 0
        pruned_individuals = get_modes_results(
            species_creators, 
            job_creator,
            performer,
            random_number_generator,
            reporter.all_species,
            reporter.persistent_ids
        )
        modes_complexity = get_maximum_complexity(pruned_individuals)
        #species_complexity = get_maximum_complexity(reporter.all_species)
        novelty = calculate_novelty!(reporter, pruned_individuals)
        change = calculate_change!(reporter, pruned_individuals)
        quick_print(generation, modes_complexity, 0, novelty, change)
        genotype_measurements = [
            BasicMeasurement("modes/individuals/$(individual.id)/genotype", individual.genotype)
            for individual in pruned_individuals
        ]
        measurements = [
            BasicMeasurement("modes/change", change),
            BasicMeasurement("modes/novelty", novelty),
            BasicMeasurement("modes/complexity", modes_complexity),
            genotype_measurements...
        ]
        update_species_list(reporter, all_species)
        reset_tag_dictionary(reporter)
        update_tag_dictionary(reporter, all_species)
        reporter.persistent_ids = get_all_ids(all_species)
        reporter.previous_modes_generation = generation
        #report = BasicReport(reporter.metric, measurements, trial, generation, true, true)
        report = nothing
        return report
    else
        update_persistent_ids(reporter, all_species)
    end
    return NullReport() 
end

function create_report(reporter::ModesReporter, state::State)
    report = create_report(
        reporter, 
        state.trial,
        state.generation, 
        state.species_creators,
        state.job_creator,
        state.performer,
        state.random_number_generator,
        state.species
    )
    return report
end
    