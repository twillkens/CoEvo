export step!
using ..Abstract

function step!(counter::Counter)::Int
    counter = typeof(counter)
    error("Default step! not implemented for $counter.")
end

function step!(counter::Counter, value::Int)::Int
    counter = typeof(counter)
    value = typeof(value)
    error("Default step! not implemented for $counter, $value.")
end