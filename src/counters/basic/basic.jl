"""
    Basic

The `Basic` submodule offers a fundamental implementation of the counter mechanism defined in 
the parent `Counters` module.

## BasicCounter

A mutable structure that implements the `Counter` interface from the `Counters` module.

### Fields:
- `current_value::Int`: Represents the current value of the counter.

### Constructors:
- `BasicCounter()`: Creates a new `BasicCounter` with a starting value of 1.

### Functions:
- `count!(counter::BasicCounter)`: Increments the `current_value` of the given `BasicCounter` by 1 and returns the value before the increment.
- `count!(c::BasicCounter, n::Int)`: Increments the `current_value` of the given `BasicCounter` by `n` times and returns a list of values before each increment.

"""
module Basic

export BasicCounter

import ..Counters: count!

using ..Counters: Counter

mutable struct BasicCounter <: Counter
    current_value::Int
    lock::ReentrantLock
end

BasicCounter() = BasicCounter(1)
BasicCounter(n::Int) = BasicCounter(n, Threads.ReentrantLock())

function count!(counter::BasicCounter)
    lock(counter.lock) do
        value = counter.current_value
        counter.current_value += 1
        return value
    end
end

function count!(c::BasicCounter, n::Int)
    lock(c.lock) do
        values = [count!(c) for _ in 1:n]
        return values
    end
end

end
