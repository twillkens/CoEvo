using ...Mutators.FunctionGraphs: FunctionGraphMutator

const BINOMIAL_RATES = Dict(
    "shrink_moderate" => Dict(
        "ADD_NODE" =>  0.0075,
        "REMOVE_NODE" => 0.01,
        "MUTATE_NODE" => 0.02,
        "MUTATE_EDGE" => 0.02,
    ),
    "shrink_harsh" => Dict(
        "ADD_NODE" =>  0.005,
        "REMOVE_NODE" => 0.01,
        "MUTATE_NODE" => 0.02,
        "MUTATE_EDGE" => 0.02,
    ),
)

const EXPONENTIAL_WEIGHTS = Dict(
    "shrink_moderate" => Dict(
        "ADD_NODE" => 75,
        "REMOVE_NODE" => 100,
        "MUTATE_NODE" => 1000,
        "MUTATE_EDGE" => 1000,
    ),
    "shrink_harsh" => Dict(
        "ADD_NODE" => 50,
        "REMOVE_NODE" => 100,
        "MUTATE_NODE" => 1000,
        "MUTATE_EDGE" => 1000,
    ),
)

const MUTATORS = Dict(
    "shrink_moderate" => FunctionGraphMutator(
        n_minimum_hidden_nodes = 0,
        recurrent_edge_probability = 0.5,
        binomial_rates = BINOMIAL_RATES["shrink_moderate"],
        max_mutations = 5,
        n_mutations_decay_rate = 0.5,
        exponential_weights = EXPONENTIAL_WEIGHTS["shrink_moderate"],
        probability_mutate_bias = 0.02,
        bias_value_range = Float32.((-π, π)),
        probability_mutate_weight = 0.02,
        weight_value_range = Float32.((-π, π)),
        noise_std = 0.01,
        probability_inject_noise_bias = 1.0 ,
        probability_inject_noise_weight = 1.0,
        function_set = FUNCTION_SETS["large"]
        validate_genotypes::Bool = false
    ),
    "shrink_harsh" => FunctionGraphMutator(
        n_minimum_hidden_nodes = 0,
        recurrent_edge_probability = 0.5,
        binomial_rates = BINOMIAL_RATES["shrink_moderate"],
        max_mutations = 5,
        n_mutations_decay_rate = 0.5,
        exponential_weights = EXPONENTIAL_WEIGHTS["shrink_moderate"],
        probability_mutate_bias = 0.02,
        bias_value_range = Float32.((-π, π)),
        probability_mutate_weight = 0.02,
        weight_value_range = Float32.((-π, π)),
        noise_std = 0.01,
        probability_inject_noise_bias = 1.0 ,
        probability_inject_noise_weight = 1.0,
        function_set = FUNCTION_SETS["large"]
        validate_genotypes::Bool = false
    ),
)