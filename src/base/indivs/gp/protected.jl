export pdiv, aq, pexp, plog, psqrt, psin, pcos, ppow, cond


# Collection of protected function for GP

"""Protected division"""
pdiv(x, y, undef=10e6) = ifelse(y == 0, x + undef, /(x,y))
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
"""Conditional function"""
#cond(x,y,z)            = ifelse(x > 0, y, z)
cond(x,y,a,b)          = ifelse(x > y, a, b)

randfloat(
    rng::AbstractRNG, 
    low::Float64 = 0.0, 
    high::Float64 = 2π
) = rand(rng, Uniform(low, high))
