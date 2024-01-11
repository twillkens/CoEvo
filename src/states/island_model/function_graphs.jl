
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
    "equal" => Dict(
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
    "shrink_major" => Dict(
        :add_node! => 0.5, 
        :remove_node! => 1.5, 
        :mutate_node! => 1.0, 
        :mutate_edge! => 1.0, 
    ), 
    "shrink_minor_stable" => Dict(
        :add_node! => 95,
        :remove_node! => 105,
        :mutate_node! => 1000,
        :mutate_edge! => 1000,
    ),
    "shrink_major_stable" => Dict(
        :add_node! => 50,
        :remove_node! => 100,
        :mutate_node! => 1000,
        :mutate_edge! => 1000,
    ),
)

const GAUSSIAN_NOISE_STD = Dict(
    "high" => 0.1,
    "moderate" => 0.05,
    "low" => 0.01,
)
