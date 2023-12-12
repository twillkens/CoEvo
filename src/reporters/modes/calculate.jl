export calculate_novelty!, calculate_change!, quick_print

using ...Metrics: measure

function calculate_novelty!(reporter::ModesReporter, genotypes::Vector{<:Genotype})
    genotypes = Set(genotypes)
    novelty = measure(reporter.novelty_metric, reporter.all_modes_genotypes, genotypes)
    union!(reporter.all_modes_genotypes, genotypes)
    return novelty
end

function calculate_change!(reporter::ModesReporter, genotypes::Vector{<:Genotype})
    genotypes = Set(genotypes)
    different_genotypes = setdiff(genotypes, reporter.previous_modes_genotypes)
    change = length(different_genotypes)
    empty!(reporter.previous_modes_genotypes)
    union!(reporter.previous_modes_genotypes, genotypes)
    return change
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