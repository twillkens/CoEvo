export MUTATION_PROBABILITIES, GAUSSIAN_NOISE_STD, make_mutators

using ....Mutators.FunctionGraphs: FunctionGraphMutator

const MUTATION_PROBABILITIES = Dict(
    "equal_stable" => Dict(
        :identity => 0.9,
        :add_function => 0.025,
        :remove_function => 0.025,
        :swap_function => 0.025,
        :redirect_connection => 0.025,
    ),
    "equal_volatile" => Dict(
        :identity => 0.0,
        :add_function => 0.25,
        :remove_function => 0.25,
        :swap_function => 0.25,
        :redirect_connection => 0.25,
    ),
    "shrink_minor" => Dict(
        :identity => 0.0, 
        :add_function => 0.95, 
        :remove_function => 1.05, 
        :swap_function => 1.0, 
        :redirect_connection => 1.0, 
    ), 

    "shrink_modest" => Dict(
        :identity => 0.0,
        :add_function => .225,
        :remove_function => .275,
        :swap_function => 0.25,
        :redirect_connection => 0.25,
    ),
    "shrink_small" => Dict(
        :identity => 0.5,
        :add_function => 1 / 9,
        :remove_function => 5 / 36,
        :swap_function => 0.125,
        :redirect_connection => 0.125,
    ),
    "shrink_hypervolatile" => Dict(
        :identity => 0.0,
        :add_function => 1 / 9, 
        :remove_function => 2 / 9,
        :swap_function => 1 / 3,
        :redirect_connection => 1 / 3
    ),
    "shrink_volatile" => Dict(
        :identity => 0.5,
        :add_function => 0.10,
        :remove_function => 0.15,
        :swap_function => 0.125,
        :redirect_connection => 0.125,
    ),
    "shrink_moderate" => Dict(
        :identity => 0.75,
        :add_function => 0.05,
        :remove_function => 0.075,
        :swap_function => 0.0625,
        :redirect_connection => 0.0625,
    ),
    "shrink_stable" => Dict(
        :identity => 0.90,
        :add_function => 0.02,
        :remove_function => 0.03,
        :swap_function => 0.025,
        :redirect_connection => 0.025,
    ),
    "shrink_stable_harsh" => Dict(
        :identity => 108 / 120,
        :add_function => 2 / 120,
        :remove_function => 4 / 120,
        :swap_function => 3 / 120,
        :redirect_connection => 3 / 120,
    ),
)

const GAUSSIAN_NOISE_STD = Dict(
    "high" => 0.1,
    "moderate" => 0.05,
    "low" => 0.01,
)

function make_mutators(substrate::FunctionGraphSubstrateConfiguration) 
    function_set = FUNCTION_SETS[substrate.function_set]
    function_probabilities = Dict(
        Symbol(func) => 1 / length(function_set) for func in function_set
    )
    mutation_probabilities = MUTATION_PROBABILITIES[substrate.mutation]
    noise_std = GAUSSIAN_NOISE_STD[substrate.noise_std]
    mutator = FunctionGraphMutator(
        function_probabilities = function_probabilities,
        mutation_probabilities = mutation_probabilities,
        noise_std = noise_std,
        validate_genotypes = false,
    )
    mutators = [mutator]
    return mutators
end