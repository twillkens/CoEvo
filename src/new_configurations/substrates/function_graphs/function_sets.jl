export FUNCTION_SETS

FUNCTION_SETS = Dict(
    "all" => [
        :IDENTITY,
        :ADD,
        :SUBTRACT,
        :MULTIPLY,
        :DIVIDE,
        :MAXIMUM,
        :MINIMUM,
        :SINE,
        :COSINE,
        :ARCTANGENT,
        :SIGMOID,
        :TANH,
        :RELU,
        :IF_LESS_THEN_ELSE,
    ],
    "circle" => [
        :IDENTITY, :ADD, :MULTIPLY, :DIVIDE, :MAXIMUM, :SINE, :COSINE, :ARCTANGENT, #:IF_LESS_THEN_ELSE
    ],
    "simple" => [:ADD, :ARCTANGENT, ]#:IF_LESS_THEN_ELSE]
)