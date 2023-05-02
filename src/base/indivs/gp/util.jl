function radianshift(x::Real)
    x - (floor(x / 2π) * 2π)
end

function randseg(rng::AbstractRNG, l)
    from, to = rand(rng, 1:l, 2)
    if from == to
        if to < l
            to += 1
        else
            from -= 1
        end
    elseif from > to
        from, to = to, from
    end
    return (from,to)
end

function swap!(v::T, from::Int, to::Int) where {T <: AbstractVector}
    val = v[from]
    v[from] = v[to]
    v[to] = val
end