module Counters

export Counter, next!

"""
    Counter

A mutable structure that maintains a numeric value. It's often used for generating sequences 
of numbers, like unique identifiers.

# Fields
- `curr::Int`: Represents the current value of the counter.
"""
mutable struct Counter
    curr::Int
end

"""
    Counter()

Create a new `Counter` instance initialized with a value of 1.
"""
Counter() = Counter(1)

"""
    next!(c::Counter)

Increment the value of the `Counter` by one and return the current value.

# Arguments
- `c::Counter`: The counter whose value is to be incremented.

# Returns
- `Int`: The incremented value of the counter.
"""
function next!(c::Counter)
    val = c.curr
    c.curr += 1
    val
end

"""
    next!(c::Counter, n::Int)

Increment the value of the `Counter` by a specified number and return a sequence of incremented values.

# Arguments
- `c::Counter`: The counter whose value is to be incremented.
- `n::Int`: The number of times the counter should be incremented.

# Returns
- `Vector{Int}`: A sequence of incremented values of the counter.
"""
function next!(c::Counter, n::Int)
    [next!(c) for _ in 1:n]
end

end