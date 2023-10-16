
@kwdef struct GraphFunction
    name::Symbol
    func::Function
    arity::Int
end

function graph_identity(x::Float32)::Float32
    return x
end

function graph_add(x::Float32, y::Float32)::Float32
    if x == Inf32 && y == -Inf32 || x == -Inf32 && y == Inf32
        return 0.0f0
    end
    return x + y
end

function graph_subtract(x::Float32, y::Float32)::Float32
    if x == Inf32 && y == Inf32 || x == -Inf32 && y == -Inf32
        return 0.0f0
    end
    return x - y
end

function graph_multiply(x::Float32, y::Float32)::Float32
    if x == 0.0f0 || y == 0.0f0
        return 0.0f0
    end
    return x * y
end

function graph_divide(x::Float32, y::Float32)::Float32
    if x == Inf32 && y == Inf32 || x == -Inf32 && y == -Inf32
        return 1.0f0
    elseif x == Inf32 && y == -Inf32 || x == -Inf32 && y == Inf32
        return -1.0f0
    elseif x > 0 && y == 0.0f0
        return Inf32
    elseif x < 0 && y == 0.0f0
        return -Inf32
    elseif y == 0.0f0 && x == 0.0f0
        return 0.0f0
    end
    return x / y
end

function graph_maximum(x::Float32, y::Float32)::Float32
    return max(x, y)
end

function graph_minimum(x::Float32, y::Float32)::Float32
    return min(x, y)
end

function graph_sin(x::Float32)::Float32
    return isinf(x) ? 0.0f0 : sin(x)
end

function graph_cosine(x::Float32)::Float32
    return isinf(x) ? 0.0f0 : cos(x)
end

function graph_sigmoid(x::Float32)::Float32
    return 1.0f0 / (1.0f0 + exp(-x))
end

function graph_tanh(x::Float32)::Float32
    return tanh(x)
end

function graph_relu(x::Float32)::Float32
    return x < 0.0f0 ? 0.0f0 : x
end

function graph_and(x::Float32, y::Float32)::Float32
    return Bool(x) && Bool(y) ? 1.0f0 : 0.0f0
end

function graph_or(x::Float32, y::Float32)::Float32
    return Bool(x) || Bool(y) ? 1.0f0 : 0.0f0
end

function graph_nand(x::Float32, y::Float32)::Float32
    return !(Bool(x) && Bool(y)) ? 1.0f0 : 0.0f0
end

function graph_xor(x::Float32, y::Float32)::Float32
    return Bool(x) ⊻ Bool(y) ? 1.0f0 : 0.0f0
end


const FUNCTION_MAP = Dict(
    :INPUT => GraphFunction(
        name = :INPUT, 
        func = graph_identity, 
        arity = 0
    ),
    :BIAS => GraphFunction(
        name = :BIAS, 
        func = graph_identity, 
        arity = 0
    ),
    :OUTPUT => GraphFunction(
        name = :OUTPUT, 
        func = graph_identity, 
        arity = 1
    ),
    :IDENTITY => GraphFunction(
        name = :IDENTITY, 
        func = graph_identity, 
        arity = 1
    ),
    :ADD => GraphFunction(
        name = :ADD, 
        func = graph_add, 
        arity = 2
    ),
    :SUBTRACT => GraphFunction(
        name = :SUBTRACT, 
        func = graph_subtract, 
        arity = 2
    ),
    :MULTIPLY => GraphFunction(
        name = :MULTIPLY, 
        func = graph_multiply, 
        arity = 2
    ),
    :DIVIDE => GraphFunction(
        name = :DIVIDE, 
        func = graph_divide, 
        arity = 2
    ),
    :MAXIMUM => GraphFunction(
        name = :MAXIMUM, 
        func = graph_maximum, 
        arity = 2
    ),
    :MINIMUM => GraphFunction(
        name = :MINIMUM, 
        func = graph_minimum, 
        arity = 2
    ),
    :SIN => GraphFunction(
        name = :SIN, 
        func = graph_sin,
        arity = 1
    ),
    :COSINE => GraphFunction(
        name = :COSINE, 
        func = graph_cosine,
        arity = 1
    ),
    :SIGMOID => GraphFunction(
        name = :SIGMOID, 
        func = graph_sigmoid,
        arity = 1
    ),
    :TANH => GraphFunction(
        name = :TANH, 
        func = graph_tanh, 
        arity = 1
    ),
    :RELU => GraphFunction(
        name = :RELU, 
        func = graph_relu,
        arity = 1
    ),
    :AND => GraphFunction(
        name = :AND, 
        func = graph_and,
        arity = 2
    ),
    :OR => GraphFunction(
        name = :OR, 
        func = graph_or,
        arity = 2
    ),
    :NAND => GraphFunction(
        name = :NAND, 
        func = graph_nand,
        arity = 2
    ),
    :XOR => GraphFunction(
        name = :XOR, 
        func = graph_xor,
        arity = 2
    ),
)