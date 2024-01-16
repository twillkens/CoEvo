module Basic

export BasicCounter

import ....Interfaces: step!

using ....Abstract

mutable struct BasicCounter <: Counter
    current_value::Int
end

BasicCounter() = BasicCounter(1)

function step!(counter::BasicCounter)
    value = counter.current_value
    counter.current_value += 1
    return value
end

function step!(c::BasicCounter, n::Int)
    values = [step!(c) for _ in 1:n]
    return values
end

end