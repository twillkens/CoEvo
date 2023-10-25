module Basic

export BasicCounter

import ..Counters: count!

using ..Counters: Counter

mutable struct BasicCounter <: Counter
    current_value::Int
end

BasicCounter() = BasicCounter(1)

function count!(counter::BasicCounter)
    value = counter.current_value
    counter.current_value += 1
    return value
end

function count!(c::BasicCounter, n::Int)
    values = [count!(c) for _ in 1:n]
    return values
end

end