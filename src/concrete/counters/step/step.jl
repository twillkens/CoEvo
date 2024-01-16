module Step

export StepCounter

import ....Interfaces: step!

using ....Abstract

mutable struct StepCounter <: Counter
    current_value::Int
    step_interval::Int
end

function step!(counter::StepCounter)
    value = counter.current_value
    counter.current_value += counter.step_interval
    return value
end

function step!(c::StepCounter, n::Int)
    values = [step!(c) for _ in 1:n]
    return values
end

end