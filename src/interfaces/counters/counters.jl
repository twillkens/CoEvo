export count!
using ..Abstract

function count!(counter::Counter)::Int
    throw(ErrorException("Default count! not implemented for $counter."))
end

function count!(counter::Counter, value::Int)::Int
    throw(ErrorException("Default count! not implemented for $counter."))
end