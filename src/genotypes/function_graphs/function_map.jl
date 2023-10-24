export FUNCTION_MAP, GraphFunction, evaluate, InputGraphFunction, BiasGraphFunction
export OutputGraphFunction, IdentityGraphFunction, AddGraphFunction, SubtractGraphFunction
export MultiplyGraphFunction, GraphDivide, MaximumGraphFunction, MinimumGraphFunction
export SineGraphFunction, CosineGraphFunction, SigmoidGraphFunction, TanhGraphFunction
export ReluGraphFunction, AndGraphFunction, OrGraphFunction, NandGraphFunction, XorGraphFunction

abstract type GraphFunction end

@inline function evaluate(func::GraphFunction, inputs::Vector{Float32})::Float32
    if length(inputs) == 1
        return evaluate(func, inputs[1])
    elseif length(inputs) == 2
        return evaluate(func, inputs[1], inputs[2])
    else
        throw(ErrorException("Unsupported arity: $(func.arity)"))
    end
end

@kwdef struct InputGraphFunction <: GraphFunction 
    name::Symbol = :INPUT
    arity::Int = 0
end

@inline function evaluate(::InputGraphFunction, x::Float32)::Float32
    throw(ArgumentError("Input function cannot be evaluated."))
end

@kwdef struct BiasGraphFunction <: GraphFunction 
    name::Symbol = :BIAS
    arity::Int = 0
end

@inline function evaluate(::BiasGraphFunction, x::Float32)::Float32
    throw(ArgumentError("Bias function cannot be evaluated."))
end

@kwdef struct OutputGraphFunction <: GraphFunction 
    name::Symbol = :OUTPUT
    arity::Int = 1
end

@inline function evaluate(::OutputGraphFunction, x::Float32)::Float32
    return x
end

@kwdef struct IdentityGraphFunction <: GraphFunction 
    name::Symbol = :IDENTITY
    arity::Int = 1
end
     

@inline function evaluate(::IdentityGraphFunction, x::Float32)::Float32
    return x
end

@kwdef struct AddGraphFunction <: GraphFunction 
    name::Symbol = :ADD
    arity::Int = 2
end

@inline function evaluate(::AddGraphFunction, x::Float32, y::Float32)::Float32
    if x == Inf32 && y == -Inf32 || x == -Inf32 && y == Inf32
        return 0.0f0
    end
    return x + y
end

@kwdef struct SubtractGraphFunction <: GraphFunction 
    name::Symbol = :SUBTRACT
    arity::Int = 2
end

@inline function evaluate(::SubtractGraphFunction, x::Float32, y::Float32)::Float32
    if x == Inf32 && y == Inf32 || x == -Inf32 && y == -Inf32
        return 0.0f0
    end
    return x - y
end

@kwdef struct MultiplyGraphFunction <: GraphFunction 
    name::Symbol = :MULTIPLY
    arity::Int = 2
end


@inline function evaluate(::MultiplyGraphFunction, x::Float32, y::Float32)::Float32
    if x == 0.0f0 || y == 0.0f0
        return 0.0f0
    end
    return x * y
end

@kwdef struct GraphDivide <: GraphFunction 
    name::Symbol = :DIVIDE
    arity::Int = 2
end

@inline function evaluate(::GraphDivide, x::Float32, y::Float32)::Float32
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

@kwdef struct MaximumGraphFunction <: GraphFunction 
    name::Symbol = :MAXIMUM
    arity::Int = 2
end

@inline function evaluate(::MaximumGraphFunction, x::Float32, y::Float32)::Float32
    return max(x, y)
end

@kwdef struct MinimumGraphFunction <: GraphFunction 
    name::Symbol = :MINIMUM
    arity::Int = 2
end

@inline function evaluate(::MinimumGraphFunction, x::Float32, y::Float32)::Float32
    return min(x, y)
end

@kwdef struct SineGraphFunction <: GraphFunction 
    name::Symbol = :SINE
    arity::Int = 1
end

@inline function evaluate(::SineGraphFunction, x::Float32)::Float32
    return isinf(x) ? 0.0f0 : sin(x)
end

@kwdef struct CosineGraphFunction <: GraphFunction 
    name::Symbol = :COSINE
    arity::Int = 1
end

@inline function evaluate(::CosineGraphFunction, x::Float32)::Float32
    return isinf(x) ? 1.0f0 : cos(x)
end

@kwdef struct SigmoidGraphFunction <: GraphFunction 
    name::Symbol = :SIGMOID
    arity::Int = 1
end

@inline function evaluate(::SigmoidGraphFunction, x::Float32)::Float32
    return 1.0f0 / (1.0f0 + exp(-x))
end

@kwdef struct TanhGraphFunction <: GraphFunction 
    name::Symbol = :TANH
    arity::Int = 1
end

@inline function evaluate(::TanhGraphFunction, x::Float32)::Float32
    return tanh(x)
end

@kwdef struct ReluGraphFunction <: GraphFunction 
    name::Symbol = :RELU
    arity::Int = 1
end

@inline function evaluate(::ReluGraphFunction, x::Float32)::Float32
    return x < 0.0f0 ? 0.0f0 : x
end

@kwdef struct AndGraphFunction <: GraphFunction 
    name::Symbol = :AND
    arity::Int = 2
end

@inline function evaluate(::AndGraphFunction, x::Float32, y::Float32)::Float32
    return Bool(x) && Bool(y) ? 1.0f0 : 0.0f0
end

@kwdef struct OrGraphFunction <: GraphFunction 
    name::Symbol = :OR
    arity::Int = 2
end

@inline function evaluate(::OrGraphFunction, x::Float32, y::Float32)::Float32
    return Bool(x) || Bool(y) ? 1.0f0 : 0.0f0
end

@kwdef struct NandGraphFunction <: GraphFunction 
    name::Symbol = :NAND
    arity::Int = 2
end

@inline function evaluate(::NandGraphFunction, x::Float32, y::Float32)::Float32
    return !(Bool(x) && Bool(y)) ? 1.0f0 : 0.0f0
end

@kwdef struct XorGraphFunction <: GraphFunction 
    name::Symbol = :XOR
    arity::Int = 2
end

@inline function evaluate(::XorGraphFunction, x::Float32, y::Float32)::Float32
    return Bool(x) ⊻ Bool(y) ? 1.0f0 : 0.0f0
end



const FUNCTION_MAP = Dict(
    :INPUT => InputGraphFunction(),
    :BIAS => BiasGraphFunction(),
    :OUTPUT => OutputGraphFunction(),
    :IDENTITY => IdentityGraphFunction(),
    :ADD => AddGraphFunction(),
    :SUBTRACT => SubtractGraphFunction(),
    :MULTIPLY => MultiplyGraphFunction(),
    :DIVIDE => GraphDivide(),
    :MAXIMUM => MaximumGraphFunction(),
    :MINIMUM => MinimumGraphFunction(),
    :SINE => SineGraphFunction(),
    :COSINE => CosineGraphFunction(),
    :SIGMOID => SigmoidGraphFunction(),
    :TANH => TanhGraphFunction(),
    :RELU => ReluGraphFunction(),
    :AND => AndGraphFunction(),
    :OR => OrGraphFunction(),
    :NAND => NandGraphFunction(),
    :XOR => XorGraphFunction(),
)