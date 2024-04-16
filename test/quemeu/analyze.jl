using HypothesisTests
using StatsBase
using Bootstrap: bootstrap, BasicSampling, BasicConfInt, confint as bootstrap_confint
using Statistics
using Random
using DataStructures
using MultipleTesting


# ANALYSIS FUNCTIONS

struct StatisticalAnalysisResults
    original_p_values::SortedDict{String, Float64}
    adjusted_p_values::SortedDict{String, Float64}
    effect_sizes::SortedDict{String, Float64}
end


# Function to perform Mann-Whitney U tests
function perform_mann_whitney_u_tests(control::Vector{Float64}, groups::Vector{Vector{Float64}})
    p_values = Float64[]
    for group in groups
        test_result = MannWhitneyUTest(control, group)
        push!(p_values, pvalue(test_result))
    end
    return p_values
end

using MultipleTesting

# Function for Bonferroni correction using the MultipleTesting package
function bonferroni_correction(p_values::Vector{Float64})
    adjusted_p_values = adjust(p_values, Bonferroni())
    return adjusted_p_values
end


# Function to calculate Glass's D for effect size
function calculate_effect_sizes(control::Vector{Float64}, groups::Vector{Vector{Float64}})
    effect_sizes = Float64[]
    for group in groups
        mean_diff = mean(group) - mean(control)
        sd_control = std(control)
        push!(effect_sizes, mean_diff / sd_control)
    end
    return effect_sizes
end

# Function to run the analysis
function run_analysis(
    control_name::String, 
    data::Dict{String, Vector{Float64}}, 
    threshold::Float64 = 0.95;
    verbose::Bool = true
)
    control = data[control_name]
    group_names = filter(name -> name != control_name, sort(collect(keys(data))))
    groups = [data[name] for name in group_names]

    # Perform Kruskal-Wallis Test
    kw_p_value = pvalue(KruskalWallisTest([[control]; groups]...))
    if verbose
        p = round(kw_p_value, digits=4)
        println("Kruskal-Wallis Test p-value: $p")
    end

    if kw_p_value < threshold
        original_p_values_vector = perform_mann_whitney_u_tests(control, groups)
        adjusted_p_values_vector = bonferroni_correction(original_p_values_vector)
        effect_sizes_vector = calculate_effect_sizes(control, groups)

        # Create dictionaries from the vectors
        original_p_values = Dict(zip(group_names, original_p_values_vector))
        adjusted_p_values = Dict(zip(group_names, adjusted_p_values_vector))
        effect_sizes = Dict(zip(group_names, effect_sizes_vector))

        results = StatisticalAnalysisResults(original_p_values, adjusted_p_values, effect_sizes)

        if verbose
            print_analysis_results(control_name, results)
        end

        return results
    else
        if verbose
            println("No significant differences found among groups.")
        end
        return StatisticalAnalysisResults(SortedDict(), SortedDict(), SortedDict())
    end
end


# Function to print the analysis results
function print_analysis_results(control_name::String, results::StatisticalAnalysisResults)
    println("\nStatistical Analysis Results:\n")
    println("Original P-Values:")
    for (group, p_value) in results.original_p_values
        p_value = round(p_value, digits=4)
        println("$group vs $control_name: p = $p_value")
    end

    println("\nAdjusted P-Values after Bonferroni Correction:")
    for (group, p_value) in results.adjusted_p_values
        p_value = round(p_value, digits=4)
        println("$group vs $control_name: p = $p_value")
    end

    println("\nEffect Sizes (Glass's D):")
    for (group, effect_size) in results.effect_sizes
        effect_size = round(effect_size, digits=4)
        println("$group vs $control_name: Glass's D = $effect_size")
    end
end

# EXAMPLE USAGE

function create_test_data()

    # Set a seed for reproducibility
    Random.seed!(42)

    # Creating example data
    Control = 50 .+ 10 .* randn(30)
    A = 50 .+ 10 .* randn(30) # Similar to control
    B = 52 .+ 10 .* randn(30) # Slightly higher than control
    C = 60 .+ 10 .* randn(30) # Significantly higher than control
    D = 50 .+ 20 .* randn(30) # Higher variance
    E = 40 .+ 10 .* randn(30) # Significantly lower than control

    # Data dictionary
    data = Dict("Control" => Control, "A" => A, "B" => B, "C" => C, "D" => D, "E" => E)
    return data
end

function run_test()
    data = create_test_data()
    run_analysis("Control", data)
end
