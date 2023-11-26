export NSGAIIEvaluator, NSGAIIEvaluation
export evaluate, make_individual_tests, calculate_fitnesses, check_for_nan_in_fitnesses
export create_records, evaluate, get_raw_fitnesses, get_scaled_fitnesses

Base.@kwdef struct NSGAIIEvaluator <: Evaluator 
    scalar_fitness_evaluator::ScalarFitnessEvaluator = ScalarFitnessEvaluator()
    maximize::Bool = true
    perform_disco::Bool = true
    max_clusters::Int = -1
    distance_method::Symbol = :disco_average
    function_minimums::Union{Vector{Float64}, Nothing} = nothing
    function_maximums::Union{Vector{Float64}, Nothing} = nothing
end

struct NSGAIIEvaluation <: Evaluation
    id::String
    records::Vector{NSGAIIRecord}
    scalar_fitness_evaluation::ScalarFitnessEvaluation
end

function convert_to_sorteddict(dict::Dict{Int, Dict{Int, Float64}})::SortedDict{Int, SortedDict{Int, Float64}}
    sorted_outer = SortedDict{Int, SortedDict{Int, Float64}}()

    for (outer_key, inner_dict) in dict
        sorted_inner = SortedDict{Int, Float64}()
        for (inner_key, value) in inner_dict
            sorted_inner[inner_key] = value
        end
        sorted_outer[outer_key] = sorted_inner
    end

    return sorted_outer
end

function make_individual_tests(
    individuals::Vector{<:Individual},
    outcomes::Dict{Int, Dict{Int, Float64}}
)
    ids = [individual.id for individual in individuals]
    outcomes = convert_to_sorteddict(outcomes)
    individual_tests = SortedDict{Int, Vector{Float64}}(
        id => [pair.second for pair in outcomes[id]]
        for id in ids
    )
    return individual_tests
end

function calculate_fitnesses(individual_tests::SortedDict{Int, Vector{Float64}})
    [sum(tests) / length(tests) for tests in values(individual_tests)]
end

function check_for_nan_in_fitnesses(fitnesses::Vector{Float64})
    if any(isnan, fitnesses)
        throw(ErrorException("NaN in fitnesses"))
    end
end

function create_records(
    individual_tests::SortedDict{Int, Vector{Float64}},
    fitnesses::Vector{Float64},
    disco_fitnesses::Vector{Float64}
)
    records = NSGAIIRecord[]
    for (index, id_tests) in enumerate(individual_tests)
        id, tests = id_tests
        record = NSGAIIRecord(
            id = id, 
            fitness = fitnesses[index], 
            disco_fitness = disco_fitnesses[index],
            tests = tests
        )
        push!(records, record)
    end
    records
end

function evaluate(
    evaluator::NSGAIIEvaluator,
    random_number_generator::AbstractRNG,
    species::AbstractSpecies,
    outcomes::Dict{Int, Dict{Int, Float64}}
)
    scalar_fitness_evaluation = evaluate(
        evaluator.scalar_fitness_evaluator, random_number_generator, species, outcomes
    )
    individuals = [species.population ; species.children]
    filter!(individual -> individual.id in keys(outcomes), individuals)
    
    individual_tests = make_individual_tests(individuals, outcomes)

    fitnesses = calculate_fitnesses(individual_tests)
    check_for_nan_in_fitnesses(fitnesses)

    if evaluator.perform_disco
        individual_tests = get_derived_tests(
            random_number_generator, individual_tests, evaluator.max_clusters
        )
    end

    disco_fitnesses = calculate_fitnesses(individual_tests)
    check_for_nan_in_fitnesses(disco_fitnesses)

    records = create_records(individual_tests, fitnesses, disco_fitnesses)

    criterion = evaluator.maximize ? Maximize() : Minimize()
    sorted_records = nsga_sort!(
        records, criterion, evaluator.function_minimums, evaluator.function_maximums
    )
    evaluation = NSGAIIEvaluation(species.id, sorted_records, scalar_fitness_evaluation)

    return evaluation
end

function get_raw_fitnesses(evaluation::NSGAIIEvaluation)
    fitnesses = get_raw_fitnesses(evaluation.scalar_fitness_evaluation)
    return fitnesses
end

function get_scaled_fitnesses(evaluation::NSGAIIEvaluation)
    fitnesses = get_scaled_fitnesses(evaluation.scalar_fitness_evaluation)
    return fitnesses
end