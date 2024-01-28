
using ...Evaluators.NSGAII: individual_tests_to_individual_distinctions, make_individual_tests
using StatsBase
using DataStructures

function competitive_fitness_sharing!(E::SortedDict{Int, Vector{Float64}})
    O = dict_to_matrix(E)
    index_sums = sum(O, dims=2)
    for (id, outcomes) in E
        for index in eachindex(outcomes)
            if outcomes[index] == 1
                outcomes[index] = 1 / index_sums[index]
            end
        end
    end
end

function competitive_fitness_sharing!(
    population_outcomes::SortedDict{Int, Vector{Float64}}, 
    archive_outcomes::SortedDict{Int, Vector{Float64}}
)
    temp_dict = merge(population_outcomes, archive_outcomes)
    competitive_fitness_sharing!(temp_dict)
end


function update_distinction_archive!(
    species_creator::ArchiveSpeciesCreator, 
    species::ArchiveSpecies, 
    state::State
)
    length_archive_before = length(species.archive)
    results = state.results
    outcomes = get_individual_outcomes(results)
    population_tests = make_individual_tests(species.population, outcomes)
    population_distinctions = individual_tests_to_individual_distinctions(population_tests)
    archive_tests = make_individual_tests(species.active_archive_individuals, outcomes)
    archive_distinctions = individual_tests_to_individual_distinctions(archive_tests)
    competitive_fitness_sharing!(population_distinctions, archive_distinctions)

    population_distinction_sums = Dict(
        id => sum(distinctions) for (id, distinctions) in population_distinctions
    )
    max_, min_, mean_ = maximum(values(population_distinction_sums)), minimum(values(population_distinction_sums)), mean(values(population_distinction_sums))
    println("$(species.id)_population max = $max_, min = $min_, mean = $mean_")

    archive_distinction_sums = Dict(
        id => sum(distinctions) for (id, distinctions) in archive_distinctions
    )
    max_, min_, mean_ = maximum(values(archive_distinction_sums)), minimum(values(archive_distinction_sums)), mean(values(archive_distinction_sums))
    println("$(species.id)_archive max = $max_, min = $min_, mean = $mean_")
    # make a vector of pairs, and sort it by distnction sum
    best_population = [
        species[id] 
        for (id, _) in sort(collect(population_distinction_sums), by = x -> x[2], rev = true)
    ]
    worst_archive = [
        species[id] 
        for (id, _) in sort(collect(archive_distinction_sums), by = x -> x[2], rev = false)[1:species_creator.n_archive]
    ]
    println("length_best_population = ", length(best_population))
    println("length_archive_before = ", length(species.archive))
    filter!(individual -> individual ∉ worst_archive, species.archive)
    println("length_archive_after_filter = ", length(species.archive))
    for individual in best_population
        if length(species.archive) < species_creator.max_archive_length
            if individual ∉ species.archive
                push!(species.archive, individual)
            end
        end
    end
    println("length_archive_after_append = ", length(species.archive))
    new_active_candidates = [
        individual for individual in species.archive if individual ∉ species.population
    ]
    println("length_new_active_candidates = ", length(new_active_candidates))
    new_active = sample(state.rng, new_active_candidates, species_creator.max_archive_matches; replace = false)
    println("length_new_active = ", length(new_active))
    empty!(species.active_archive_individuals)
    append!(species.active_archive_individuals, new_active)
    if length(species.archive) != length_archive_before
        error("length(species.archive) = $(length(species.archive)) != length_archive_before = $length_archive_before")
    end
end
using Random

function filter_sorted_dict(d::SortedDict{Int, Vector{Float64}})
    # Create a new SortedDict to store the filtered results
    filtered_dict = SortedDict{Int, Vector{Float64}}()

    # Store the last seen vector and its key
    last_vector = Vector{Float64}()
    last_key = nothing

    for (key, vector) in d
        # If this is the first iteration or the vector differs from the last seen
        if last_key === nothing || vector != last_vector
            # Update the last seen vector and key, and add the entry to the filtered dict
            last_vector = vector
            last_key = key
            filtered_dict[key] = vector
        end
    end

    return filtered_dict
end

function update_distinction_archive_2!(
    species_creator::ArchiveSpeciesCreator, 
    species::ArchiveSpecies, 
    state::State
)
    length_archive_before = length(species.archive)
    println("length_archive_before = ", length_archive_before)
    results = state.results
    outcomes = get_individual_outcomes(results)
    population_tests = make_individual_tests(species.population, outcomes)
    population_distinctions = individual_tests_to_individual_distinctions(population_tests)
    archive_tests = make_individual_tests(species.active_archive_individuals, outcomes)
    archive_distinctions = individual_tests_to_individual_distinctions(archive_tests)
    distinctions = merge(population_distinctions, archive_distinctions)
    distinctions = filter_sorted_dict(distinctions)
    competitive_fitness_sharing!(distinctions)
    distinction_sums = Dict(
        id => sum(distinctions) for (id, distinctions) in distinctions
    )
    max_, min_, mean_ = maximum(values(distinction_sums)), minimum(values(distinction_sums)), mean(values(distinction_sums))
    println("\n------------------------------------------------")
    println("$(species.id)_distinctions, max = $max_, min = $min_, mean = $mean_")
    sorted_individuals = [
        species[id] 
        for (id, _) in sort(collect(distinction_sums), by = x -> x[2], rev = true)
    ]
    println("length_sorted_individuals = ", length(sorted_individuals))
    println("length_set = ", length(Set(indiv.id for indiv in sorted_individuals)))
    println("\n----SORTED_INDIVIDUALS------")
    n_truncate = min(100, length(sorted_individuals))
    sorted_individuals = sorted_individuals[1:n_truncate]
    species.archive = sorted_individuals
    println("length_archive_after_append = ", length(species.archive))
end

function update_distinction_archive_simple!(
    species_creator::ArchiveSpeciesCreator, 
    species::ArchiveSpecies, 
    state::State
)
    #length_archive_before = length(species.archive)
    results = state.results
    outcomes = get_individual_outcomes(results)
    population_tests = make_individual_tests(species.population, outcomes)
    population_distinctions = individual_tests_to_individual_distinctions(population_tests)
    competitive_fitness_sharing!(population_distinctions)

    population_distinction_sums = Dict(
        id => sum(distinctions) for (id, distinctions) in population_distinctions
    )
    max_, min_, mean_ = maximum(values(population_distinction_sums)), minimum(values(population_distinction_sums)), mean(values(population_distinction_sums))
    println("\n------------------------------------------------")
    println("$(species.id)_population max = $max_, min = $min_, mean = $mean_")
    sorted_population = [
        species[id] 
        for (id, _) in sort(collect(population_distinction_sums), by = x -> x[2], rev = true)
    ]
    filter!(individual -> individual ∉ species.archive, sorted_population)
    if sum([distinction_sum for distinction_sum in values(population_distinction_sums)]) == 0.0
        shuffle!(state.rng, sorted_population)
    end
    append!(species.archive, sorted_population[1:species_creator.n_archive])
    for individual in sorted_population[1:species_creator.n_archive]
        id = individual.id
        fitness = population_distinction_sums[id]
        genotype = round.(individual.genotype.genes; digits = 3)
        phenotype = round.(individual.phenotype.values; digits = 3)
        println("id = $id, fitness = $fitness, genotype = $genotype, phenotype = $phenotype")
    end
        
    while length(species.archive) > species_creator.max_archive_length
        deleteat!(species.archive, 1)
    end
    println("length_archive_after_append = ", length(species.archive))
    new_active_candidates = [
        individual for individual in species.archive if individual ∉ species.population
    ]
    #println("length_new_active_candidates = ", length(new_active_candidates))
    n_sample = min(species_creator.max_archive_matches, length(new_active_candidates))
    new_active = sample(state.rng, new_active_candidates, n_sample ; replace = false)
    #println("length_new_active = ", length(new_active))
    empty!(species.active_archive_individuals)
    append!(species.active_archive_individuals, new_active)
end