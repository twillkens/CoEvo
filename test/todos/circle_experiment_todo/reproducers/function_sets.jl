
const FUNCTION_SETS = Dict(
    "large" => [
        :IDENTITY,
        :ADD,
        :SUBTRACT,
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