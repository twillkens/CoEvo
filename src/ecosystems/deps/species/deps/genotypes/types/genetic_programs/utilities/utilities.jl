
module Utilities

export protected_division, analytic_quotioent, protected_exponential, protected_natural_log
export protected_square_root, protected_sine, protected_cosine, protected_exponentiation
export if_less_then_else, random_float

"""
    Protected division.
"""
protected_division(x, y, undef=10e6) = ifelse(y == 0, undef, x/y)

"""
    Analytic quotient.
"""
analytic_quotioent(x, y) = x / sqrt(1 + y * y)

"""
    Protected exponential.
"""
protected_exponential(x, undef=10e15) = ifelse(x >= 32, x + undef, exp(x))

"""
    Protected natural log.
"""
protected_natural_log(x, undef=10e6) = ifelse(x == 0, -undef, log(abs(x)))

"""
    Protected square root.
"""
protected_square_root(x) = sqrt(abs(x))

"""
    Protected sine operation.
"""
protected_sine(x, undef=π) = isinf(x) ? undef : sin(x)

"""
    Protected cosine operation.
"""
protected_cosine(x, undef=π) = isinf(x) ? undef : cos(x)

"""
    Protected exponentiation operation.
"""
function protected_exponentiation(x, y, undef=10e6)
    if y >= 10
        x + y + undef
    elseif y < 1
        abs(x)^y
    else
        x^y
    end
end

"""
    iflt conditional operation.
"""
function if_less_then_else(first_arg, second_arg, then_arg, else_arg)
    first_arg = isa(first_arg, Expr) ? eval(first_arg) : first_arg
    second_arg = isa(second_arg, Expr) ? eval(second_arg) : second_arg
    if first_arg < second_arg
        then_arg = isa(then_arg, Expr) ? eval(then_arg) : then_arg
        return then_arg
    else
        else_arg = isa(else_arg, Expr) ? eval(else_arg) : else_arg
        return else_arg
    end
end

"""
    Generates a random float number in a specified range.
"""
function random_float(rng::AbstractRNG, low::Float64 = 0.0, high::Float64 = 2π)
    return rand(rng, Uniform(low, high))
end

end