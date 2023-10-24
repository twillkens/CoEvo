module Interfaces

export count!

using ..Counters.Abstract: Counter

function count!(counter::Counter)::Int
    throw(ErrorException("Default count! not implemented for $counter."))
end

function count!(counter::Counter, value::Int)::Int
    throw(ErrorException("Default count! not implemented for $counter."))
end

end