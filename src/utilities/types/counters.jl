module Counters

export Counter, next!

mutable struct Counter
    curr::Int
end

Counter() = Counter(1)

function next!(c::Counter)
    val = c.curr
    c.curr += 1
    val
end

function next!(c::Counter, n::Int)
    [next!(c) for _ in 1:n]
end

end