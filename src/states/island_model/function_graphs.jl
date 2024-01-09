
FUNCTION_SETS = Dict(
    "all" => [
        :IDENTITY,
        :ADD,
        :MULTIPLY,
        :DIVIDE,
        :SINE,
        :COSINE,
        :SIGMOID,
        :TANH,
        :RELU,
        :MAXIMUM,
        :MINIMUM,
        :IF_LESS_THEN_ELSE,
        :MODULO,
        :NATURAL_LOG,
        :EXP,
    ],
    "circle" => [
        :IDENTITY, :ADD, :MULTIPLY, :DIVIDE, :MAXIMUM, :SINE, :COSINE, :ARCTANGENT, #:IF_LESS_THEN_ELSE
    ],
    "simple" => [:ADD, :RELU, :SINE, :IF_LESS_THEN_ELSE],
    "simple_minmax" => [:ADD, :RELU, :SINE, :COSINE, :MAXIMUM, :MINIMUM, :IF_LESS_THEN_ELSE],
)

const MUTATION_PROBABILITIES = Dict(
    "equal_stable" => Dict(
        :identity => 0.9,
        :add_node! => 0.025,
        :remove_node! => 0.025,
        :mutate_node! => 0.025,
        :mutate_edge! => 0.025,
    ),
    "equal_volatile" => Dict(
        :identity => 0.0,
        :add_node! => 0.25,
        :remove_node! => 0.25,
        :mutate_node! => 0.25,
        :mutate_edge! => 0.25,
    ),
    "shrink_minor" => Dict(
        :add_node! => 0.95, 
        :remove_node! => 1.05, 
        :mutate_node! => 1.0, 
        :mutate_edge! => 1.0, 
    ), 

    "shrink_modest" => Dict(
        :identity => 0.0,
        :add_node! => .225,
        :remove_node! => .275,
        :mutate_node! => 0.25,
        :mutate_edge! => 0.25,
    ),
    "shrink_small" => Dict(
        :identity => 0.5,
        :add_node! => 1 / 9,
        :remove_node! => 5 / 36,
        :mutate_node! => 0.125,
        :mutate_edge! => 0.125,
    ),
    "shrink_hypervolatile" => Dict(
        :identity => 0.0,
        :add_node! => 1 / 9, 
        :remove_node! => 2 / 9,
        :mutate_node! => 1 / 3,
        :mutate_edge! => 1 / 3
    ),
    "shrink_volatile" => Dict(
        :identity => 0.5,
        :add_node! => 0.10,
        :remove_node! => 0.15,
        :mutate_node! => 0.125,
        :mutate_edge! => 0.125,
    ),
    "shrink_moderate" => Dict(
        :identity => 0.75,
        :add_node! => 0.05,
        :remove_node! => 0.075,
        :mutate_node! => 0.0625,
        :mutate_edge! => 0.0625,
    ),
    "shrink_stable" => Dict(
        :identity => 0.90,
        :add_node! => 0.02,
        :remove_node! => 0.03,
        :mutate_node! => 0.025,
        :mutate_edge! => 0.025,
    ),
    "shrink_stable_harsh" => Dict(
        :identity => 108 / 120,
        :add_node! => 2 / 120,
        :remove_node! => 4 / 120,
        :mutate_node! => 3 / 120,
        :mutate_edge! => 3 / 120,
    ),
)

const GAUSSIAN_NOISE_STD = Dict(
    "high" => 0.1,
    "moderate" => 0.05,
    "low" => 0.01,
)
