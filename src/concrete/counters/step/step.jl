module Step

export StepCounter

import ....Interfaces: count!

using ....Abstract

mutable struct StepCounter <: Counter
    current_value::Int
    step_interval::Int
end

function count!(counter::StepCounter)
    value = counter.current_value
    counter.current_value += counter.step_interval
    return value
end

function count!(c::StepCounter, n::Int)
    values = [count!(c) for _ in 1:n]
    return values
end

end