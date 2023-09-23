
const Terminal = Union{Symbol, Real, Function}
const FuncAlias = Union{Symbol, Function}


# Collection of protected function for GP

"""Protected division"""
pdiv(x, y, undef=10e6) = ifelse(y == 0, undef, /(x,y))
"""Analytic quotient"""
aq(x, y)               = x / sqrt(1 + y * y)
"""Protected exponential"""
pexp(x, undef=10e15)   = ifelse(x >= 32, x + undef  , exp(x))
"""Protected natural log"""
plog(x, undef=10e6)    = ifelse(x == 0 , -undef   , log(abs(x)))
"""Protected sq.root"""
psqrt(x)               = sqrt(abs(x))
"""Protected sin(x)"""
psin(x, undef=π)    = isinf(x) ? undef : sin(x)
"""Protected cos(x)"""
pcos(x, undef=π)    = isinf(x) ? undef : cos(x)
"""Protected exponentiation operation"""
function ppow(x, y, undef=10e6)
    if y>=10
        x + y + undef
    elseif y < 1
        abs(x)^y
    else
        x^y
    end
end

function iflt(first_arg, second_arg, then_arg, else_arg)
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

randfloat(
    rng::AbstractRNG, 
    low::Float64 = 0.0, 
    high::Float64 = 2π
) = rand(rng, Uniform(low, high))
